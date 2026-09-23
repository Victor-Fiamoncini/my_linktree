require "rails_helper"

RSpec.describe ScheduleMeetingTool do
  let(:open_slot) { CheckAvailabilityUseCase.new.execute[:slots].first }

  it "advertises the name, description and the four arguments agents must supply" do
    expect(described_class.tool_name).to eq("schedule_meeting")
    expect(described_class.description).to include("check_availability")
    expect(described_class.input_schema.to_h[:properties].keys).to contain_exactly(
      :name, :email, :company, :slot_start
    )
  end

  it "records the agent connection before answering" do
    expect {
      described_class.call(name: "Jane", email: "jane@example.com", slot_start: open_slot)
    }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("schedule_meeting")
  end

  it "books the slot and echoes the booking back as JSON text" do
    response = nil

    expect {
      response = described_class.call(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: open_slot)
    }.to change(Booking, :count).by(1)

    expect(response.to_h[:isError]).to be_falsey
    expect(JSON.parse(response.content.first[:text], symbolize_names: true)).to eq(
      name: "Jane", email: "jane@example.com", company: "Acme", slot_start: open_slot
    )
  end

  it "reports mcp.meeting.booked with the contact redacted rather than raw" do
    events = captured_events do
      described_class.call(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: open_slot)
    end

    payload = find_event(events, "mcp.meeting.booked")[:payload]
    expect(payload).to include(slot_start: open_slot, has_company: true, contact_domain: "example.com")
    expect(payload[:contact_digest]).to match(/\A[0-9a-f]{12}\z/)
    expect(payload.values.join).not_to include("jane@example.com")
  end

  it "reports has_company: false when the agent supplied no company" do
    events = captured_events do
      described_class.call(name: "Jane", email: "jane@example.com", slot_start: open_slot)
    end

    expect(find_event(events, "mcp.meeting.booked")[:payload]).to include(has_company: false)
  end

  # An MCP error is isError: true at HTTP 200 — it reaches neither rescue_from nor the gem's
  # exception reporter, so these two paths are the only trace a failed booking leaves.
  it "returns an MCP error instead of raising when the slot is already taken" do
    Booking.create!(name: "Bob", email: "bob@example.com", slot_start: open_slot)

    response = described_class.call(name: "Jane", email: "jane@example.com", slot_start: open_slot)

    expect(response.to_h[:isError]).to be(true)
    expect(response.content.first[:text]).to eq("Slot unavailable")
  end

  it "returns an MCP error instead of raising when a required field is missing" do
    response = described_class.call(name: "", email: "jane@example.com", slot_start: open_slot)

    expect(response.to_h[:isError]).to be(true)
    expect(response.content.first[:text]).to eq("Missing required fields")
  end

  it "reports mcp.meeting.rejected with the reason and the redacted contact" do
    Booking.create!(name: "Bob", email: "bob@example.com", slot_start: open_slot)

    events = captured_events do
      described_class.call(name: "Jane", email: "jane@example.com", slot_start: open_slot)
    end

    payload = find_event(events, "mcp.meeting.rejected")[:payload]
    expect(payload).to include(
      severity: "warn", reason: "Slot unavailable", slot_start: open_slot, contact_domain: "example.com"
    )
    expect(find_event(events, "mcp.meeting.booked")).to be_nil
  end
end

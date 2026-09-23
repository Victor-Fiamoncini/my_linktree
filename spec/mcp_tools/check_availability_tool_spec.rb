require "rails_helper"

RSpec.describe CheckAvailabilityTool do
  it "advertises the name and description the MCP server lists for agents" do
    expect(described_class.tool_name).to eq("check_availability")
    expect(described_class.description).to include("slots")
  end

  it "records the agent connection before answering" do
    expect { described_class.call }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("check_availability")
  end

  it "returns the timezone and open slots as JSON text" do
    response = described_class.call

    expect(response.to_h[:isError]).to be_falsey
    payload = JSON.parse(response.content.first[:text], symbolize_names: true)
    expect(payload[:timezone]).to eq("America/Sao_Paulo")
    expect(payload[:slots]).to all(match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z\z/))
  end

  it "stops offering a slot once it has been booked" do
    taken = JSON.parse(described_class.call.content.first[:text])["slots"].first
    Booking.create!(name: "Bob", email: "bob@example.com", slot_start: taken)

    slots = JSON.parse(described_class.call.content.first[:text])["slots"]

    expect(slots).not_to include(taken)
  end
end

require "rails_helper"

SQL_PAYLOADS = [
  "'; DROP TABLE bookings; --",
  "' OR '1'='1",
  "1); SELECT pg_sleep(5); --",
  "\\'; DELETE FROM knowledge_chunks WHERE ''='"
].freeze

RSpec.describe "SQL injection", type: :request do
  let(:mcp_headers) { { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" } }

  def call_tool(name, arguments = {})
    post "/api/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: name, arguments: arguments } }.to_json, headers: mcp_headers
    response.parsed_body.dig("result", "content", 0, "text")
  end

  def first_slot
    JSON.parse(call_tool("check_availability"))["slots"].first
  end

  SQL_PAYLOADS.each do |payload|
    context "with #{payload.inspect}" do
      it "stores it verbatim as a booking's name and company" do
        call_tool("schedule_meeting", name: payload, email: "jane@example.com", company: payload, slot_start: first_slot)

        expect(Booking.sole).to have_attributes(name: payload, company: payload)
      end

      it "rejects it as a slot without touching the bookings table" do
        Booking.create!(name: "Existing", email: "existing@example.com", slot_start: 1.week.from_now)

        expect(call_tool("schedule_meeting", name: "Jane", email: "jane@example.com", slot_start: payload)).to eq("Slot unavailable")
        expect(Booking.sole.name).to eq("Existing")
      end

      # The description only reaches Postgres as an embedding vector, never as SQL text.
      it "matches it as a job description without touching the corpus" do
        stub_openai
        chunk = create_knowledge_chunk(axis: 0)

        post "/api/job_match", params: { job_description: payload }.to_json, headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:ok)
        expect(KnowledgeChunk.sole).to eq(chunk)
      end

      it "can't pick a locale that isn't allow-listed" do
        post "/api/contact", params: { name: "Jane", email: "not-an-email", message: "Hi", locale: payload }.to_json, headers: { "Content-Type" => "application/json" }

        expect(response.parsed_body["errors"]).to eq("email" => I18n.t("contacts.errors.invalid_email", locale: :en))
      end
    end
  end
end

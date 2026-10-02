require "rails_helper"

# Rate-limit counts are pinned per endpoint in spec/requests; these check what an abusive client
# can make the app spend, and that garbage input stays a cheap, quiet 4xx.
RSpec.describe "Denial of service", type: :request do
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }
  let(:mcp_headers) { json_headers.merge("Accept" => "application/json, text/event-stream") }
  let(:malformed_bodies) { { "truncated JSON" => "{\"name\": ", "deeply nested JSON" => "#{"[" * 200}#{"]" * 200}" } }
  let!(:sent_to_model) { stub_openai }

  def match_job_rpc(job_description, id: 1)
    { jsonrpc: "2.0", id: id, method: "tools/call", params: { name: "match_job", arguments: { job_description: job_description } } }
  end

  def openai_requests
    WebMock::RequestRegistry.instance.times_executed(WebMock::RequestPattern.new(:post, /api\.openai\.com/))
  end

  before { create_knowledge_chunk(axis: 0) }

  %w[/contact /job_match /api/hire].each do |path|
    it "answers malformed bodies to #{path} with a 400, not an error-level event" do
      malformed_bodies.each do |label, body|
        events = captured_events { post path, params: body, headers: json_headers }

        expect(response).to have_http_status(:bad_request), label
        expect(response.parsed_body).to eq("message" => "Malformed request body")
        expect(events.map { |event| event[:payload][:severity] }).not_to include("error")
      end
    end
  end

  it "answers malformed MCP bodies with a JSON-RPC error, not a 500" do
    malformed_bodies.each do |label, body|
      events = captured_events { post "/api/mcp", params: body, headers: mcp_headers }

      expect(response).to have_http_status(:bad_request), label
      expect(response.parsed_body.dig("error", "code")).to be_between(-32700, -32600)
      expect(find_event(events, "api.error")).to be_nil
    end
  end

  # The match_job limiters only read single-object bodies, so a batch must never be executed.
  it "refuses a JSON-RPC batch of match_job calls without billing any of them" do
    post "/api/mcp", params: (1..20).map { |id| match_job_rpc("Rails role", id: id) }.to_json, headers: mcp_headers

    expect(response).to have_http_status(:bad_request)
    expect(openai_requests).to eq(0)
  end

  it "rejects an over-long job description on both surfaces before calling OpenAI" do
    oversized = "x" * (MatchJobUseCase::MAX_LENGTH + 1)

    post "/job_match", params: { job_description: oversized }.to_json, headers: json_headers
    expect(response).to have_http_status(:unprocessable_content)

    post "/api/mcp", params: match_job_rpc(oversized).to_json, headers: mcp_headers
    expect(response.parsed_body.dig("result", "isError")).to be(true)

    expect(openai_requests).to eq(0)
  end

  it "bills OpenAI for at most 3 matches in a burst from one IP, however it rotates X-Forwarded-For" do
    10.times do |index|
      post "/job_match", params: { job_description: "Rails role" }.to_json,
        headers: json_headers.merge("CF-Connecting-IP" => "7.7.7.7", "X-Forwarded-For" => "10.0.0.#{index}")
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(sent_to_model.size).to eq(3)
  end

  # Each booking takes a real slot and mails whatever address it was given.
  it "stops booking slots and sending mail at the daily cap, however many IPs the spammer uses" do
    travel_to Time.zone.parse("2026-09-28 09:00")

    call = ->(name, arguments, ip) do
      rpc = { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: name, arguments: arguments } }
      perform_enqueued_jobs { post "/api/mcp", params: rpc.to_json, headers: mcp_headers.merge("CF-Connecting-IP" => ip) }
    end

    call.call("check_availability", {}, "9.9.9.9")
    slots = JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))["slots"]
    expect(slots.size).to be > Api::McpController::BOOKING_DAILY_LIMIT

    (Api::McpController::BOOKING_DAILY_LIMIT + 1).times do |index|
      call.call("schedule_meeting", { name: "Spam", email: "victim#{index}@example.com", slot_start: slots[index] }, "10.9.0.#{index}")
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(Booking.count).to eq(Api::McpController::BOOKING_DAILY_LIMIT)
    expect(ActionMailer::Base.deliveries.size).to eq(Api::McpController::BOOKING_DAILY_LIMIT * 2)
  end

  it "bills OpenAI for at most 5 MCP matches in a burst from one IP" do
    10.times { post "/api/mcp", params: match_job_rpc("Rails role").to_json, headers: mcp_headers.merge("CF-Connecting-IP" => "8.8.8.8") }

    expect(response).to have_http_status(:too_many_requests)
    expect(sent_to_model.size).to eq(5)
  end
end

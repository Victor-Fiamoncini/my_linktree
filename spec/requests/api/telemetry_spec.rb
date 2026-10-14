require "rails_helper"

RSpec.describe "Api::Telemetry", type: :request do
  it "returns recent connections as JSON" do
    AgentConnection.create!(tool: "get_resume")

    get "/api/telemetry"

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body.size).to eq(1)
    expect(body.first["tool"]).to eq("get_resume")
  end

  it "returns an empty array when there are no connections" do
    get "/api/telemetry"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([])
  end

  it "rate limits after 60 requests from the same IP within the window" do
    headers = { "X-Forwarded-For" => "9.9.9.9" }

    60.times { get "/api/telemetry", headers: headers }
    get "/api/telemetry", headers: headers

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["message"]).to eq("Too many requests")
  end

  it "rate limits by the real connection IP when no X-Forwarded-For header is present" do
    60.times { get "/api/telemetry" }
    get "/api/telemetry"

    expect(response).to have_http_status(:too_many_requests)
  end

  it "reports an api.error event with the class and backtrace when the action blows up" do
    allow(ListRecentConnectionsUseCase).to receive(:new).and_raise(ArgumentError, "boom")

    events = captured_events { get "/api/telemetry" }

    expect(response).to have_http_status(:internal_server_error)
    payload = find_event(events, "api.error")[:payload]
    expect(payload).to include(severity: "error", error_class: "ArgumentError", error_message: "boom")
    expect(payload[:backtrace]).to be_an(Array)
  end

  # An exception that never propagated has no backtrace; &.first(5) is what stops the error
  # handler from raising a second, more confusing error on top of the first.
  it "still reports api.error when the exception carries no backtrace" do
    error = ArgumentError.new("boom")
    allow(error).to receive(:backtrace).and_return(nil)
    allow(ListRecentConnectionsUseCase).to receive(:new).and_raise(error)

    events = captured_events { get "/api/telemetry" }

    expect(response).to have_http_status(:internal_server_error)
    expect(find_event(events, "api.error")[:payload][:backtrace]).to be_nil
  end

  it "reports an api.rate_limited event naming the throttled endpoint" do
    60.times { get "/api/telemetry" }

    events = captured_events { get "/api/telemetry" }

    expect(response).to have_http_status(:too_many_requests)
    expect(find_event(events, "api.rate_limited")[:payload]).to include(
      severity: "warn", controller: "telemetry", action: "index"
    )
  end

  it "rate limits by the visitor's IP, walking past the Cloudflare and kamal-proxy hops" do
    # Production chain: Cloudflare puts the visitor in X-Forwarded-For, kamal-proxy
    # (forward_headers: true) appends Cloudflare's edge, Thruster appends kamal-proxy's
    # Docker IP. trusted_proxies (config/initializers/trusted_proxies.rb) skips both hops.
    visitor_a = { "X-Forwarded-For" => "1.1.1.1, 173.245.48.1, 172.18.0.2" }
    visitor_b = { "X-Forwarded-For" => "2804:30c:1f75:a100:aaaa:bbbb:cccc:dddd, 173.245.48.1, 172.18.0.2" }

    60.times { get "/api/telemetry", headers: visitor_a }
    get "/api/telemetry", headers: visitor_a
    expect(response).to have_http_status(:too_many_requests)

    get "/api/telemetry", headers: visitor_b
    expect(response).to have_http_status(:ok)
  end

  it "ignores forged X-Forwarded-For and CF-Connecting-IP values when the hop isn't Cloudflare" do
    forged = ->(index) { { "X-Forwarded-For" => "1.1.1.#{index}, 203.0.113.9, 172.18.0.2", "CF-Connecting-IP" => "1.1.1.#{index}" } }

    60.times { |index| get "/api/telemetry", headers: forged.call(index) }
    get "/api/telemetry", headers: forged.call(99)
    expect(response).to have_http_status(:too_many_requests)
  end
end

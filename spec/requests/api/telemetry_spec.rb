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

  it "rate limits by the real visitor IP, not Cloudflare's edge IP, when proxied through Cloudflare" do
    # kamal-proxy appends its previous hop (Cloudflare's edge) to X-Forwarded-For, so Rails sees
    # "<visitor ip>, <cloudflare ip>" — trusted_proxies (config/initializers/trusted_proxies.rb)
    # must walk past the Cloudflare hop or every visitor collapses into one shared bucket.
    cloudflare_edge_ip = "173.245.48.1"
    visitor_a = { "X-Forwarded-For" => "1.1.1.1, #{cloudflare_edge_ip}" }
    visitor_b = { "X-Forwarded-For" => "2.2.2.2, #{cloudflare_edge_ip}" }

    60.times { get "/api/telemetry", headers: visitor_a }
    get "/api/telemetry", headers: visitor_a
    expect(response).to have_http_status(:too_many_requests)

    get "/api/telemetry", headers: visitor_b
    expect(response).to have_http_status(:ok)
  end
end

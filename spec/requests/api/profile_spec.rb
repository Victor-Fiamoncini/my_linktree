require "rails_helper"

RSpec.describe "Api::Profile", type: :request do
  it "returns the profile as JSON" do
    get "/api/profile"

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body).to include("name", "experiences", "education")
  end

  it "rate limits after 60 requests from the same IP within the window" do
    headers = { "X-Forwarded-For" => "9.9.9.9" }

    60.times { get "/api/profile", headers: headers }
    get "/api/profile", headers: headers

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["message"]).to eq("Too many requests")
  end

  it "rate limits by the real connection IP when no X-Forwarded-For header is present" do
    60.times { get "/api/profile" }
    get "/api/profile"

    expect(response).to have_http_status(:too_many_requests)
  end
end

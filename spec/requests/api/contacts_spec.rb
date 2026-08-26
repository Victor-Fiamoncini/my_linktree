require "rails_helper"

RSpec.describe "Api::Contacts", type: :request do
  let(:valid_params) { { name: "Jane", email: "jane@example.com", message: "Hello!" } }

  it "sends the email and returns 204 on success" do
    post "/api/contact", params: valid_params.to_json, headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:no_content)
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "returns 400 with MissingRequiredFieldsError when a field is missing" do
    post "/api/contact", params: valid_params.merge(name: "").to_json, headers: { "Content-Type" => "application/json" }

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body["name"]).to eq("MissingRequiredFieldsError")
  end

  it "rate limits after 2 requests from the same IP within the window" do
    headers = { "Content-Type" => "application/json", "X-Forwarded-For" => "9.9.9.9" }

    2.times { post "/api/contact", params: valid_params.to_json, headers: headers }
    post "/api/contact", params: valid_params.to_json, headers: headers

    expect(response).to have_http_status(:too_many_requests)
  end

  it "skips rate limiting when no IP header is present" do
    headers = { "Content-Type" => "application/json" }

    3.times do
      post "/api/contact", params: valid_params.to_json, headers: headers
      expect(response).to have_http_status(:no_content)
    end
  end
end

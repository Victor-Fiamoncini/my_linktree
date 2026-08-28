require "rails_helper"

RSpec.describe "Contacts", type: :request do
  let(:valid_params) { { name: "Jane", email: "jane@example.com", message: "Hello!" } }
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }

  def post_contact(params, headers: json_headers)
    post "/contact", params: params.to_json, headers: headers
  end

  it "sends the email and returns a success message" do
    perform_enqueued_jobs { post_contact(valid_params) }

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["message"]).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "returns a field error when name is blank" do
    post_contact(valid_params.merge(name: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("name" => "can't be blank")
  end

  it "returns a field error when email is blank" do
    post_contact(valid_params.merge(email: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("email" => "can't be blank")
  end

  it "returns a field error when email is invalid" do
    post_contact(valid_params.merge(email: "not-an-email"))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("email" => "is invalid")
  end

  it "returns a field error when message is blank" do
    post_contact(valid_params.merge(message: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("message" => "can't be blank")
  end

  it "returns multiple field errors when several fields are blank" do
    post_contact({ name: "", email: "", message: "" })

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"].keys).to contain_exactly("name", "email", "message")
  end

  it "rate limits after 2 requests from the same IP within the window" do
    headers = json_headers.merge("X-Forwarded-For" => "9.9.9.9")

    2.times { post_contact(valid_params, headers: headers) }
    post_contact(valid_params, headers: headers)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["message"]).to include("Too many requests")
  end

  it "rate limits by the real connection IP when no X-Forwarded-For header is present" do
    2.times { post_contact(valid_params) }
    post_contact(valid_params)

    expect(response).to have_http_status(:too_many_requests)
    expect(response.parsed_body["message"]).to include("Too many requests")
  end

  it "returns an error when the CSRF token is invalid" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    begin
      post_contact(valid_params)
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["message"]).to include("session expired")
  end
end

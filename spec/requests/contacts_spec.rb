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

  describe "structured events" do
    it "reports contact.message.sent with the address redacted" do
      events = captured_events { perform_enqueued_jobs { post_contact(valid_params) } }

      payload = find_event(events, "contact.message.sent")[:payload]
      expect(payload).to include(locale: "en", message_length: valid_params[:message].length, contact_domain: "example.com")
      expect(payload[:contact_digest]).to match(/\A[0-9a-f]{12}\z/)
      expect(payload.to_json).not_to include("jane@example.com")
    end

    it "reports contact.message.rejected naming the invalid fields" do
      events = captured_events { post_contact(valid_params.merge(email: "not-an-email")) }

      expect(find_event(events, "contact.message.rejected")[:payload]).to eq(severity: "warn", fields: [ "email" ])
    end

    it "reports contact.csrf_rejected when the token is missing" do
      original = ActionController::Base.allow_forgery_protection
      ActionController::Base.allow_forgery_protection = true

      events = captured_events { post_contact(valid_params) }

      expect(response).to have_http_status(:unprocessable_content)
      expect(find_event(events, "contact.csrf_rejected")[:payload]).to eq(severity: "warn")
    ensure
      ActionController::Base.allow_forgery_protection = original
    end

    it "reports contact.rate_limited once the window is exhausted" do
      headers = json_headers.merge("X-Forwarded-For" => "5.5.5.5")
      2.times { post_contact(valid_params, headers: headers) }

      events = captured_events { post_contact(valid_params, headers: headers) }

      expect(response).to have_http_status(:too_many_requests)
      expect(find_event(events, "contact.rate_limited")[:payload]).to eq(severity: "warn")
    end
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

  it "returns translated messages when locale is pt-BR" do
    post_contact(valid_params.merge(name: "", locale: "pt-BR"))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("name" => "não pode ficar em branco")
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

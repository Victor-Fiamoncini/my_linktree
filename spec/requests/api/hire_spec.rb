require "rails_helper"

RSpec.describe "Api::Hire", type: :request do
  let(:valid_params) { { name: "Jane", contact: "jane@example.com", brief: "Build me a thing" } }
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }

  def post_hire(params, headers: json_headers)
    post "/api/hire", params: params.to_json, headers: headers
  end

  it "sends the email, logs an agent connection, and returns a success message" do
    expect {
      perform_enqueued_jobs { post_hire(valid_params) }
    }.to change(AgentConnection, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["message"]).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(AgentConnection.last.tool).to eq("hire")
  end

  it "returns a field error when name is blank" do
    post_hire(valid_params.merge(name: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("name" => "can't be blank")
  end

  it "returns a field error when contact is blank" do
    post_hire(valid_params.merge(contact: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("contact" => "can't be blank")
  end

  it "returns a field error when brief is blank" do
    post_hire(valid_params.merge(brief: ""))

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"]).to eq("brief" => "can't be blank")
  end

  it "returns multiple field errors when several fields are blank" do
    post_hire({ name: "", contact: "", brief: "" })

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body["errors"].keys).to contain_exactly("name", "contact", "brief")
  end

  it "logs an agent connection even when validation fails" do
    expect {
      post_hire(valid_params.merge(name: ""))
    }.to change(AgentConnection, :count).by(1)
  end

  describe "structured events" do
    it "reports hire.request.received with the contact redacted" do
      events = captured_events { perform_enqueued_jobs { post_hire(valid_params.merge(agent: "claude")) } }

      payload = find_event(events, "hire.request.received")[:payload]
      expect(payload).to include(agent: "claude", brief_length: valid_params[:brief].length, contact_domain: "example.com")
      expect(payload.to_json).not_to include("jane@example.com")
    end

    it "reports hire.request.rejected naming the invalid fields" do
      events = captured_events { post_hire(valid_params.merge(name: "", brief: "")) }

      expect(find_event(events, "hire.request.rejected")[:payload]).to include(severity: "warn")
      expect(find_event(events, "hire.request.rejected")[:payload][:fields]).to contain_exactly("name", "brief")
    end

    it "reports api.rate_limited once the window is exhausted" do
      headers = json_headers.merge("X-Forwarded-For" => "6.6.6.6")
      2.times { post_hire(valid_params, headers: headers) }

      events = captured_events { post_hire(valid_params, headers: headers) }

      expect(response).to have_http_status(:too_many_requests)
      expect(find_event(events, "api.rate_limited")[:payload]).to include(
        severity: "warn", controller: "hire", action: "create"
      )
    end
  end

  it "rate limits after 2 requests from the same IP within the window" do
    headers = json_headers.merge("X-Forwarded-For" => "9.9.9.9")

    2.times { post_hire(valid_params, headers: headers) }
    post_hire(valid_params, headers: headers)

    expect(response).to have_http_status(:too_many_requests)
  end

  it "rate limits by the real connection IP when no X-Forwarded-For header is present" do
    2.times { post_hire(valid_params) }
    post_hire(valid_params)

    expect(response).to have_http_status(:too_many_requests)
  end
end

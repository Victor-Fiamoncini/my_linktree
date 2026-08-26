require "rails_helper"

RSpec.describe "Contacts", type: :request do
  let(:valid_params) { { name: "Jane", email: "jane@example.com", message: "Hello!" } }

  it "sends the email and redirects with a success notice" do
    post "/contact", params: valid_params

    expect(response).to redirect_to(root_path(anchor: "contact"))
    expect(flash[:notice]).to be_present
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "redirects with an alert when a field is missing" do
    post "/contact", params: valid_params.merge(name: "")

    expect(response).to redirect_to(root_path(anchor: "contact"))
    expect(flash[:alert]).to include("Missing required fields")
  end

  it "rate limits after 2 requests from the same IP within the window" do
    headers = { "X-Forwarded-For" => "9.9.9.9" }

    2.times { post "/contact", params: valid_params, headers: headers }
    post "/contact", params: valid_params, headers: headers

    expect(flash[:alert]).to include("Too many requests")
  end

  it "skips rate limiting when no IP header is present" do
    3.times do
      post "/contact", params: valid_params
      expect(flash[:notice]).to be_present
    end
  end
end

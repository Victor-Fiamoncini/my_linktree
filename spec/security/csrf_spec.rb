require "rails_helper"

RSpec.describe "Cross-site request forgery", type: :request do
  let(:json_headers) { { "Content-Type" => "application/json", "Accept" => "application/json" } }
  let(:endpoints) do
    {
      "/api/contact" => { name: "Jane", email: "jane@example.com", message: "Hi" },
      "/api/job_match" => { job_description: "Rails role" }
    }
  end
  let!(:sent_to_model) { stub_openai }

  # Off in the test env (see config/environments/test.rb); these specs are about turning it on.
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  before { create_knowledge_chunk(axis: 0) }

  def csrf_token
    get "/en"
    Nokogiri::HTML(response.body).at("meta[name='csrf-token']")["content"]
  end

  def post_with_token(path, params, token)
    perform_enqueued_jobs { post path, params: params.to_json, headers: json_headers.merge("X-CSRF-Token" => token) }
  end

  # The control: without it, every rejection below could be a broken setup instead of protection.
  it "accepts a token from the visitor's own session" do
    endpoints.each do |path, params|
      post_with_token(path, params, csrf_token)

      expect(response).to have_http_status(:ok), path
    end
  end

  it "rejects a forged token without sending mail or calling OpenAI" do
    endpoints.each do |path, params|
      csrf_token
      post_with_token(path, params, "forged-#{SecureRandom.base64(32)}")

      expect(response).to have_http_status(:unprocessable_content), path
    end

    expect(ActionMailer::Base.deliveries).to be_empty
    expect(sent_to_model).to be_empty
  end

  it "rejects a valid token lifted from another visitor's session" do
    endpoints.each do |path, params|
      stolen = csrf_token
      reset!
      csrf_token

      post_with_token(path, params, stolen)

      expect(response).to have_http_status(:unprocessable_content), path
    end
  end

  it "doesn't let another origin read the browser endpoints' responses" do
    endpoints.each do |path, params|
      post_with_token(path, params, csrf_token)

      expect(response.headers.keys.grep(/\AAccess-Control-/i)).to be_empty
    end
  end

  # CSRF is exempt on /api/* because there's no ambient authority to ride: no session cookie to
  # send and no credentialed CORS to read the answer with.
  it "keeps the CSRF-exempt API cookie-free and never allows credentialed CORS" do
    post "/api/hire", params: { name: "Jane", contact: "jane@example.com", brief: "Hi" }.to_json,
      headers: json_headers.merge("Origin" => "https://evil.example")
    expect(response).to have_http_status(:ok)
    expect(response.headers["Set-Cookie"]).to be_nil

    post "/api/mcp", params: { jsonrpc: "2.0", id: 1, method: "tools/list" }.to_json,
      headers: json_headers.merge("Accept" => "application/json, text/event-stream", "Origin" => "https://evil.example")
    expect(response).to have_http_status(:ok)
    expect(response.headers["Set-Cookie"]).to be_nil
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://evil.example")
    expect(response.headers["Access-Control-Allow-Credentials"]).to be_nil
  end
end

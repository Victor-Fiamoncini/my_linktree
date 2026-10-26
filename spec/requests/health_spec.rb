require "rails_helper"

RSpec.describe "Health check", type: :request do
  it "serves /up without a CSP, so its inline green background renders" do
    get "/up"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("background-color: green")
    expect(response.headers["Content-Security-Policy"]).to be_nil
  end

  it "keeps the CSP on every other page" do
    get "/en"

    expect(response.headers["Content-Security-Policy"]).to include("style-src 'self'")
  end
end

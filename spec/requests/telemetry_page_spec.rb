require "rails_helper"

RSpec.describe "TelemetryPage", type: :request do
  it "renders the telemetry page" do
    get "/telemetry"

    expect(response).to have_http_status(:ok)
  end
end

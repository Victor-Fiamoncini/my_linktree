require "rails_helper"

RSpec.describe "TelemetryPage", type: :request do
  it "renders the telemetry page in English" do
    get "/en/telemetry"

    expect(response).to have_http_status(:ok)
  end

  it "renders the telemetry page in Portuguese" do
    get "/pt-BR/telemetry"

    expect(response).to have_http_status(:ok)
  end
end

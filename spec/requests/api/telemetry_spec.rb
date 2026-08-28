require "rails_helper"

RSpec.describe "Api::Telemetry", type: :request do
  it "returns recent connections as JSON" do
    AgentConnection.create!(tool: "get_resume")

    get "/api/telemetry"

    expect(response).to have_http_status(:ok)
    body = response.parsed_body
    expect(body.size).to eq(1)
    expect(body.first["tool"]).to eq("get_resume")
  end

  it "returns an empty array when there are no connections" do
    get "/api/telemetry"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq([])
  end
end

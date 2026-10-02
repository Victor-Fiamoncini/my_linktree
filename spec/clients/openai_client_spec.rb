require "rails_helper"

RSpec.describe OpenaiClient do
  subject(:client) { described_class.new(api_key: "openai-key") }

  let(:endpoint) { "https://api.openai.com/v1/responses" }

  it "posts the body to the Responses API and returns the parsed response" do
    stub = stub_request(:post, endpoint)
      .with(headers: { "Authorization" => "Bearer openai-key" }, body: { model: "gpt-test" }.to_json)
      .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { output: [] }.to_json)

    expect(client.respond(body: { model: "gpt-test" })).to eq("output" => [])
    expect(stub).to have_been_requested
  end

  it "raises with the status code when the API fails" do
    stub_request(:post, endpoint).to_return(status: 429, body: "{}")

    expect { client.respond(body: {}) }.to raise_error(OpenaiClient::Error, /HTTP 429/)
  end

  it "reads the key from credentials by default" do
    expect(described_class.new.instance_variable_get(:@api_key)).to eq("test-openai-key")
  end
end

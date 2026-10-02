# Fakes OpenAI's HTTP endpoints so the real clients run end to end. Returns the list that each
# Responses API request body is appended to, for specs that inspect what the model was sent.
module OpenaiStubs
  def stub_openai(sources: [ 1 ])
    sent = []

    stub_request(:post, OpenaiEmbedder::ENDPOINT.to_s)
      .to_return(body: { data: [ { index: 0, embedding: unit_vector(0) } ] }.to_json)
    stub_request(:post, OpenaiClient::ENDPOINT.to_s).to_return do |request|
      sent << JSON.parse(request.body)
      output = [ { type: "message", content: [ { type: "output_text", text: { paragraphs: [ { text: "Strong fit.", sources: sources } ] }.to_json } ] } ]

      { body: { status: "completed", output: output, usage: { input_tokens: 1, output_tokens: 1 } }.to_json }
    end

    sent
  end
end

RSpec.configure do |config|
  config.include OpenaiStubs
end

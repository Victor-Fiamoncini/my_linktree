require "rails_helper"

RSpec.describe OpenaiEmbedder do
  subject(:embedder) { described_class.new(api_key: "openai-key") }

  let(:endpoint) { "https://api.openai.com/v1/embeddings" }

  def embeddings_response(*vectors)
    { status: 200, headers: { "Content-Type" => "application/json" },
      body: { data: vectors.each_with_index.map { |vector, index| { embedding: vector, index: index } }.reverse }.to_json }
  end

  it "posts the texts with the model and dimensions, and returns vectors in input order" do
    stub = stub_request(:post, endpoint)
      .with(
        headers: { "Authorization" => "Bearer openai-key" },
        body: { input: [ "a", "b" ], model: "text-embedding-3-small", dimensions: 1024 }.to_json
      )
      .to_return(embeddings_response([ 1.0 ], [ 2.0 ]))

    expect(embedder.embed([ "a", "b" ])).to eq([ [ 1.0 ], [ 2.0 ] ])
    expect(stub).to have_been_requested
  end

  it "splits large inputs into batches" do
    stub_request(:post, endpoint).to_return(
      embeddings_response(*Array.new(described_class::BATCH_SIZE) { [ 0.0 ] }),
      embeddings_response([ 1.0 ])
    )

    vectors = embedder.embed(Array.new(described_class::BATCH_SIZE + 1, "text"))

    expect(vectors.size).to eq(described_class::BATCH_SIZE + 1)
    expect(a_request(:post, endpoint)).to have_been_made.twice
  end

  it "raises with the status code when the API fails" do
    stub_request(:post, endpoint).to_return(status: 429, body: "{}")

    expect { embedder.embed([ "a" ]) }.to raise_error(OpenaiEmbedder::Error, /HTTP 429/)
  end

  it "reads the key from credentials by default" do
    expect(described_class.new.instance_variable_get(:@api_key)).to eq("test-openai-key")
  end
end

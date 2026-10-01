class OpenaiEmbedder
  ENDPOINT = URI("https://api.openai.com/v1/embeddings")
  MODEL = "text-embedding-3-small"
  # Shortened from the model's native 1536 to fit the vector(1024) column.
  DIMENSIONS = 1024
  BATCH_SIZE = 128

  class Error < StandardError; end

  def initialize(api_key: Rails.application.credentials.dig(:rag, :openai_api_key))
    @api_key = api_key
  end

  def embed(texts)
    texts.each_slice(BATCH_SIZE).flat_map { |batch| request(batch) }
  end

  private

  def request(batch)
    http_request = Net::HTTP::Post.new(ENDPOINT, "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}")
    http_request.body = { input: batch, model: MODEL, dimensions: DIMENSIONS }.to_json

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 30) { |http| http.request(http_request) }
    raise Error, "OpenAI embeddings request failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)["data"].sort_by { |item| item["index"] }.map { |item| item["embedding"] }
  end
end

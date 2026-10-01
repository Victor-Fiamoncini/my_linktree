class OpenaiClient
  ENDPOINT = URI("https://api.openai.com/v1/responses")

  class Error < StandardError; end

  def initialize(api_key: Rails.application.credentials.dig(:rag, :openai_api_key), read_timeout: 60)
    @api_key = api_key
    @read_timeout = read_timeout
  end

  # Returns the parsed Responses API body.
  def respond(body:)
    http_request = Net::HTTP::Post.new(ENDPOINT, "Content-Type" => "application/json", "Authorization" => "Bearer #{@api_key}")
    http_request.body = body.to_json

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: @read_timeout) { |http| http.request(http_request) }
    raise Error, "OpenAI responses request failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end
end

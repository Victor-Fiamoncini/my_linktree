class GithubReadmeClient
  API_HOST = "api.github.com"

  class Error < StandardError; end

  def initialize(token: Rails.application.credentials.dig(:rag, :github_token))
    @token = token
  end

  # Returns the raw README markdown, or nil when the repo has none.
  def fetch(owner:, repo:)
    uri = URI::HTTPS.build(host: API_HOST, path: "/repos/#{owner}/#{repo}/readme")
    http_request = Net::HTTP::Get.new(uri, "Accept" => "application/vnd.github.raw+json", "User-Agent" => "my_linktree")
    http_request["Authorization"] = "Bearer #{@token}" if @token.present?

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 15) { |http| http.request(http_request) }
    return if response.is_a?(Net::HTTPNotFound)
    raise Error, "GitHub README request for #{owner}/#{repo} failed with HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    response.body.force_encoding(Encoding::UTF_8)
  end
end

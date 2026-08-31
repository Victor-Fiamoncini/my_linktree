module Api
  class McpController < BaseController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool ].freeze

    CORS_METHOD_HEADERS = {
      "Access-Control-Allow-Methods" => "POST, GET, DELETE, OPTIONS",
      "Access-Control-Allow-Headers" => "Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version"
    }.freeze

    SITE_HOST = URI.parse(SeoConfig::SITE_URL).host

    ALLOWED_HOSTS = [ SITE_HOST, SITE_HOST.delete_prefix("www.") ].freeze

    ALLOWED_ORIGINS = ALLOWED_HOSTS.map { |host| "https://#{host}" }.freeze

    RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

    before_action :set_cors_headers

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create,
               unless: -> { request.options? }, store: RATE_LIMIT_STORE
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier },
               unless: -> { !schedule_meeting_call? }, only: :create, store: RATE_LIMIT_STORE

    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    def create
      return head :ok if request.options?

      return render(json: server_description) if request.get? && !event_stream_request?

      server = MCP::Server.new(name: "my_linktree", tools: TOOLS)
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(
        server, stateless: true, allowed_hosts: ALLOWED_HOSTS, allowed_origins: ALLOWED_ORIGINS
      )
      status, headers, body = transport.handle_request(request)

      headers.each { |key, value| response.set_header(key, value) }
      self.status = status
      self.response_body = body
    end

    private

    def set_cors_headers
      CORS_METHOD_HEADERS.each { |key, value| response.set_header(key, value) }

      origin = request.headers["Origin"]
      return unless origin && ALLOWED_ORIGINS.include?(origin)

      response.set_header("Access-Control-Allow-Origin", origin)
      response.set_header("Vary", "Origin")
    end

    def event_stream_request?
      request.accept.to_s.include?("text/event-stream")
    end

    def server_description
      {
        name: "my_linktree",
        transport: "streamable-http",
        usage: "POST JSON-RPC 2.0: initialize, tools/list, tools/call",
        tools: TOOLS.map(&:tool_name)
      }
    end

    def render_too_many_requests
      render json: { message: "Too many requests", action: "Please wait a moment before trying again." }, status: :too_many_requests
    end

    def schedule_meeting_call?
      return false unless request.post?

      parsed = JSON.parse(request.body.read)
      parsed["method"] == "tools/call" && parsed.dig("params", "name") == "schedule_meeting"
    rescue JSON::ParserError, TypeError
      false
    ensure
      request.body&.rewind
    end
  end
end

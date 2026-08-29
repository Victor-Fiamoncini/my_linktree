module Api
  class McpController < BaseController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool ].freeze

    CORS_HEADERS = {
      "Access-Control-Allow-Origin" => "*",
      "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
      "Access-Control-Allow-Headers" => "Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version"
    }.freeze

    SITE_HOST = URI.parse(SeoConfig::SITE_URL).host

    ALLOWED_HOSTS = [ SITE_HOST, SITE_HOST.delete_prefix("www.") ].freeze

    # In-process store instead of the app-wide Solid Cache store: Solid Cache round-trips to the
    # Postgres cache database, which for this app is a separate managed instance reachable only
    # over the public internet (measured 300ms-4s per query from the Hetzner VPS, vs. Solid
    # Cache's own local-network expectations) — latency this endpoint can't absorb, since external
    # MCP harnesses (Claude, ChatGPT, etc.) apply their own short timeouts when probing a connector.
    # A single Kamal server with no WEB_CONCURRENCY runs Puma in one process, so an in-memory store
    # is already shared across every thread handling these requests; resetting counters on deploy
    # is an acceptable trade-off for a short-window rate limit.
    RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

    before_action :set_cors_headers

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create,
               unless: -> { request.options? }, store: RATE_LIMIT_STORE
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier },
               unless: -> { !schedule_meeting_call? }, only: :create, store: RATE_LIMIT_STORE

    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    def create
      return head :ok if request.options?

      return render(json: server_description) if request.get?

      server = MCP::Server.new(name: "my_linktree", tools: TOOLS)
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(
        server, stateless: true, allowed_hosts: ALLOWED_HOSTS
      )
      status, headers, body = transport.handle_request(request)

      headers.each { |key, value| response.set_header(key, value) }
      self.status = status
      self.response_body = body
    end

    private

    def set_cors_headers
      CORS_HEADERS.each { |key, value| response.set_header(key, value) }
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

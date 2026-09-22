module Api
  class McpController < BaseController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool ].freeze

    CORS_METHOD_HEADERS = {
      "Access-Control-Allow-Methods" => "POST, GET, DELETE, OPTIONS",
      "Access-Control-Allow-Headers" => "Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version"
    }.freeze

    before_action :set_cors_headers

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create, unless: -> { request.options? }
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier }, unless: -> { !schedule_meeting_call? }, only: :create

    def create
      return head :ok if request.options?

      return render(json: server_description) if request.get? && !event_stream_request?

      server = MCP::Server.new(
        name: "my_linktree",
        title: SeoConfig::SITE_NAME,
        website_url: SeoConfig::SITE_URL,
        icons: [
          MCP::Icon.new(src: SeoConfig::MCP_ICON_192, mime_type: "image/png", sizes: "192x192"),
          MCP::Icon.new(src: SeoConfig::MCP_ICON_512, mime_type: "image/png", sizes: "512x512")
        ],
        tools: TOOLS
      )
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(
        server, stateless: true, dns_rebinding_protection: false
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
      return unless origin

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

    def schedule_meeting_call?
      jsonrpc_method == "tools/call" && jsonrpc_tool == "schedule_meeting"
    end

    def jsonrpc_method
      jsonrpc_payload["method"]
    end

    def jsonrpc_tool
      jsonrpc_payload.dig("params", "name")
    end

    # Memoized: both rate limiters and the 429 handler need the method and tool name, and the
    # body can only be read once. The rewind is what lets the transport read it afterwards.
    def jsonrpc_payload
      @jsonrpc_payload ||= parse_jsonrpc_body
    end

    def parse_jsonrpc_body
      return {} unless request.post?

      parsed = JSON.parse(request.body.read)
      parsed.is_a?(Hash) ? parsed : {}
    rescue JSON::ParserError, TypeError
      {}
    ensure
      request.body&.rewind
    end

    def rate_limited_event_payload
      super.merge(jsonrpc_method: jsonrpc_method, tool: jsonrpc_tool)
    end
  end
end

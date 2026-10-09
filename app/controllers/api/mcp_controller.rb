module Api
  class McpController < PublicController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool, MatchJobTool ].freeze

    CORS_METHOD_HEADERS = {
      "Access-Control-Allow-Methods" => "POST, GET, DELETE, OPTIONS",
      "Access-Control-Allow-Headers" => "Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version"
    }.freeze

    BOOKING_DAILY_LIMIT = 10

    before_action :set_cors_headers

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create, unless: -> { request.options? }
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier }, if: -> { schedule_meeting_call? }, only: :create
    rate_limit to: 3, within: 1.day, name: "schedule_meeting_daily", by: -> { rate_limit_identifier }, if: -> { schedule_meeting_call? }, only: :create
    # After the per-IP limiters, so one IP can't drain everyone's bookings.
    rate_limit to: BOOKING_DAILY_LIMIT, within: 1.day, name: "schedule_meeting_global", by: -> { "all" }, with: -> { render_error :too_many_requests, "mcp.meeting.budget_exhausted", daily_limit_body("schedule_meeting"), severity: "error" }, if: -> { schedule_meeting_call? }, only: :create
    rate_limit to: 5, within: 10.minutes, name: "match_job", by: -> { rate_limit_identifier }, if: -> { match_job_call? }, only: :create
    rate_limit to: 10, within: 1.day, name: "match_job_daily", by: -> { rate_limit_identifier }, if: -> { match_job_call? }, only: :create
    rate_limit to: MatchJobUseCase::GLOBAL_DAILY_LIMIT, within: 1.day, name: "global", scope: :job_match, by: -> { "all" }, with: -> { render_error :too_many_requests, "job_match.budget_exhausted", daily_limit_body("match_job"), severity: "error", surface: "mcp" }, if: -> { billable_match_job_call? }, only: :create

    def create
      return head :ok if request.options?

      return render(json: server_description) if request.get? && !event_stream_request?

      server = MCP::Server.new(
        name: "my_linktree",
        title: SeoConfig::SITE_NAME,
        website_url: SeoConfig::SITE_URL,
        icons: [
          MCP::Icon.new(src: SeoConfig::MCP_ICON_192, mime_type: "image/png", sizes: [ "192x192" ]),
          MCP::Icon.new(src: SeoConfig::MCP_ICON_512, mime_type: "image/png", sizes: [ "512x512" ])
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
      jsonrpc.tool_call?("schedule_meeting")
    end

    def match_job_call?
      jsonrpc.tool_call?("match_job")
    end

    def billable_match_job_call?
      match_job_call? && MatchJobUseCase.acceptable?(jsonrpc.arguments["job_description"])
    end

    def jsonrpc
      @jsonrpc ||= JsonRpcRequest.new(request)
    end

    def daily_limit_body(tool)
      { message: "Daily limit reached", action: "#{tool} has reached its daily limit. Please try again tomorrow." }
    end

    def rate_limited_event_payload
      super.merge(jsonrpc_method: jsonrpc.method_name, tool: jsonrpc.tool)
    end
  end
end

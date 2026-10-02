module Api
  class McpController < BaseController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool, MatchJobTool ].freeze

    CORS_METHOD_HEADERS = {
      "Access-Control-Allow-Methods" => "POST, GET, DELETE, OPTIONS",
      "Access-Control-Allow-Headers" => "Content-Type, Accept, Mcp-Session-Id, Mcp-Protocol-Version"
    }.freeze

    GLOBAL_DAILY_LIMIT = 100
    BOOKING_DAILY_LIMIT = 10

    before_action :set_cors_headers

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create, unless: -> { request.options? }
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier }, if: -> { schedule_meeting_call? }, only: :create
    rate_limit to: 3, within: 1.day, name: "schedule_meeting_daily", by: -> { rate_limit_identifier }, if: -> { schedule_meeting_call? }, only: :create
    # After the per-IP limiters, so one IP can't drain everyone's bookings.
    rate_limit to: BOOKING_DAILY_LIMIT, within: 1.day, name: "schedule_meeting_global", by: -> { "all" }, with: :render_booking_budget_exhausted, if: -> { schedule_meeting_call? }, only: :create
    rate_limit to: 5, within: 10.minutes, name: "match_job", by: -> { rate_limit_identifier }, if: -> { match_job_call? }, only: :create
    rate_limit to: 10, within: 1.day, name: "match_job_daily", by: -> { rate_limit_identifier }, if: -> { match_job_call? }, only: :create
    rate_limit to: GLOBAL_DAILY_LIMIT, within: 1.day, name: "global", scope: :job_match, by: -> { "all" }, with: :render_budget_exhausted, if: -> { billable_match_job_call? }, only: :create

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
      jsonrpc_method == "tools/call" && jsonrpc_tool == "schedule_meeting"
    end

    def match_job_call?
      jsonrpc_method == "tools/call" && jsonrpc_tool == "match_job"
    end

    def billable_match_job_call?
      match_job_call? && MatchJobUseCase.acceptable?(hash_or_empty(jsonrpc_params["arguments"])["job_description"])
    end

    def jsonrpc_method
      jsonrpc_payload["method"]
    end

    def jsonrpc_tool
      jsonrpc_params["name"]
    end

    def jsonrpc_params
      hash_or_empty(jsonrpc_payload["params"])
    end

    # Client-supplied JSON may put a string where an object belongs; dig would raise a 500.
    def hash_or_empty(value)
      value.is_a?(Hash) ? value : {}
    end

    # Memoized: the body can only be read once, and the rewind is what lets the transport read it.
    def jsonrpc_payload
      @jsonrpc_payload ||= parse_jsonrpc_body
    end

    def parse_jsonrpc_body
      return {} unless request.post?

      hash_or_empty(JSON.parse(request.body.read))
    rescue JSON::ParserError, TypeError
      {}
    ensure
      request.body&.rewind
    end

    def render_budget_exhausted
      Rails.event.notify("job_match.budget_exhausted", severity: "error", surface: "mcp")

      render json: { message: "Daily limit reached", action: "match_job has reached its daily limit. Please try again tomorrow." }, status: :too_many_requests
    end

    def render_booking_budget_exhausted
      Rails.event.notify("mcp.meeting.budget_exhausted", severity: "error")

      render json: { message: "Daily limit reached", action: "schedule_meeting has reached its daily limit. Please try again tomorrow." }, status: :too_many_requests
    end

    def rate_limited_event_payload
      super.merge(jsonrpc_method: jsonrpc_method, tool: jsonrpc_tool)
    end
  end
end

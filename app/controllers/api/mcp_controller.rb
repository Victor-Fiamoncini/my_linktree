module Api
  class McpController < BaseController
    GENERAL_RATE_LIMITER = RateLimiter.new(key_prefix: "mcp:general", max_requests: 30, window: 1.minute)
    SCHEDULE_RATE_LIMITER = RateLimiter.new(key_prefix: "mcp:schedule_meeting", max_requests: 3, window: 10.minutes)

    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool ].freeze

    def create
      ip = rate_limit_identifier

      unless GENERAL_RATE_LIMITER.allowed?(ip)
        return render json: too_many_requests_body, status: :too_many_requests
      end

      if ip.present? && schedule_meeting_call? && !SCHEDULE_RATE_LIMITER.allowed?(ip)
        return render json: too_many_requests_body, status: :too_many_requests
      end

      server = MCP::Server.new(name: "my_linktree", tools: TOOLS)
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(server, stateless: true)
      status, headers, body = transport.handle_request(request)

      self.status = status
      headers.each { |key, value| response.set_header(key, value) }
      self.response_body = body
    end

    private

    def too_many_requests_body
      { message: "Too many requests", action: "Please wait a moment before trying again." }
    end

    def schedule_meeting_call?
      parsed = JSON.parse(request.body.read)
      parsed["method"] == "tools/call" && parsed.dig("params", "name") == "schedule_meeting"
    rescue JSON::ParserError, TypeError
      false
    ensure
      request.body.rewind
    end
  end
end

module Api
  class McpController < BaseController
    TOOLS = [ GetResumeTool, ListServicesTool, CheckAvailabilityTool, ScheduleMeetingTool ].freeze

    rate_limit to: 30, within: 1.minute, by: -> { rate_limit_identifier }, only: :create
    rate_limit to: 3, within: 10.minutes, name: "schedule_meeting", by: -> { rate_limit_identifier },
               unless: -> { !schedule_meeting_call? }, only: :create

    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    def create
      server = MCP::Server.new(name: "my_linktree", tools: TOOLS)
      transport = MCP::Server::Transports::StreamableHTTPTransport.new(
        server, stateless: true, allowed_hosts: [ URI.parse(SeoConfig::SITE_URL).host ]
      )
      status, headers, body = transport.handle_request(request)

      headers.each { |key, value| response.set_header(key, value) }
      self.status = status
      self.response_body = body
    end

    private

    def render_too_many_requests
      render json: { message: "Too many requests", action: "Please wait a moment before trying again." }, status: :too_many_requests
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

# frozen_string_literal: true

# /api/mcp hands the request straight to the gem's transport, so nothing in Api::McpController
# can see which JSON-RPC method ran, which tool it called, or how it ended. The gem's own
# instrumentation hooks can, and cover all four tools without any per-tool code.
MCP.configure do |config|
  # `instrument_call` fills `data` *while* the block runs and only appends `duration:` afterwards
  # in its own `ensure`, so read it after yielding and time the call here. `data[:tool_arguments]`
  # is left out on purpose: for schedule_meeting it holds the prospect's name and email, which
  # ScheduleMeetingTool reports itself in redacted form.
  config.around_request = lambda do |data, &block|
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    block.call
  ensure
    Rails.event.tagged("mcp") do
      Rails.event.notify(
        "mcp.request",
        jsonrpc_method: data[:method],
        tool: data[:tool_name],
        client_name: data.dig(:client, :name),
        client_version: data.dig(:client, :version),
        failure: data[:error],
        cancelled: data[:cancelled],
        duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1_000).round(2)
      )
    end
  end

  # Exceptions inside the MCP server become JSON-RPC error responses and never reach
  # Api::BaseController's rescue_from, so without this they produce no log line and no Sentry event.
  config.exception_reporter = lambda do |exception, _server_context|
    Rails.error.report(exception, handled: true, source: "mcp")

    Rails.event.notify(
      "mcp.exception",
      severity: "error",
      error_class: exception.class.name,
      error_message: exception.message
    )
  end
end

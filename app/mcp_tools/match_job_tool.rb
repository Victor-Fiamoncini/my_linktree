class MatchJobTool < MCP::Tool
  tool_name "match_job"
  description "Explain how Victor Fiamoncini fits a job description. Returns a summary of his matching and transferable experience, grounded in his resume and GitHub projects, with citations."
  input_schema(properties: { job_description: { type: "string" } })

  def self.call(job_description: nil, **)
    RecordAgentConnectionUseCase.new.execute(tool: "match_job")

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = MatchJobUseCase.new.execute(job_description: job_description)

    Rails.event.notify(
      "job_match.completed",
      surface: "mcp",
      sources: result[:sources].size,
      duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round,
      # Keys containing "token" would be [FILTERED] by filter_parameters.
      llm_input: result[:usage][:input_tokens],
      llm_output: result[:usage][:output_tokens]
    )

    MCP::Tool::Response.new([ { type: "text", text: result.slice(:summary, :sources).to_json } ])
  rescue ArgumentError => e
    # isError: true at HTTP 200 reaches neither rescue_from nor the gem's exception reporter.
    Rails.event.notify("job_match.rejected", severity: "warn", surface: "mcp", reason: e.message)

    MCP::Tool::Response.new([ { type: "text", text: e.message } ], error: true)
  end
end

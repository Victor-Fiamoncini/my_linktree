module JobMatchEvents
  module_function

  def completed(surface:)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    result = yield

    Rails.event.notify(
      "job_match.completed",
      surface: surface,
      sources: result[:sources].size,
      duration_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round,
      llm_input: result[:usage][:input_tokens],
      llm_output: result[:usage][:output_tokens]
    )

    result
  end
end

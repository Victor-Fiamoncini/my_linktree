class MatchJobTool < ApplicationTool
  tool_name "match_job"
  description "Explain how Victor Fiamoncini fits a job description. Returns a summary of his matching and transferable experience, grounded in his resume and GitHub projects, with citations."
  input_schema(properties: { job_description: { type: "string" } })

  def self.perform(job_description: nil, **)
    result = JobMatchEvents.completed(surface: "mcp") do
      MatchJobUseCase.new.execute(job_description: job_description)
    end

    result.slice(:summary, :sources)
  end

  def self.rejected(error, **)
    Rails.event.notify("job_match.rejected", severity: "warn", surface: "mcp", reason: error.message)
  end
end

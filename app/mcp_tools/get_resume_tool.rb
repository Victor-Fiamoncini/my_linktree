class GetResumeTool < MCP::Tool
  tool_name "get_resume"
  description "Get Victor Fiamoncini's resume: profile, work experience, and education."
  input_schema(properties: {})

  def self.call(**)
    RecordAgentConnectionUseCase.new.execute(tool: "get_resume")

    profile = GetProfileUseCase.new.execute(locale: :en)
    MCP::Tool::Response.new([ { type: "text", text: profile.to_json } ])
  end
end

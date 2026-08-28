class GetResumeTool < MCP::Tool
  tool_name "get_resume"
  description "Get Victor Fiamoncini's resume: profile, work experience, and education."
  input_schema(properties: {})

  def self.call(**)
    UseCases::RecordAgentConnectionUseCase.new.execute(tool: "get_resume")

    profile = UseCases::GetProfileUseCase.new.execute
    MCP::Tool::Response.new([ { type: "text", text: profile.to_json } ])
  end
end

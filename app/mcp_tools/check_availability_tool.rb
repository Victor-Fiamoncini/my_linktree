class CheckAvailabilityTool < MCP::Tool
  tool_name "check_availability"
  description "Check available meeting slots with Victor Fiamoncini."
  input_schema(properties: {})

  def self.call(**)
    UseCases::RecordAgentConnectionUseCase.new.execute(tool: "check_availability")

    result = UseCases::CheckAvailabilityUseCase.new.execute
    MCP::Tool::Response.new([ { type: "text", text: result.to_json } ])
  end
end

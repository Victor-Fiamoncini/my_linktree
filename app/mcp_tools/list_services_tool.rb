class ListServicesTool < MCP::Tool
  tool_name "list_services"
  description "List the services Victor Fiamoncini offers."
  input_schema(properties: {})

  def self.call(**)
    UseCases::RecordAgentConnectionUseCase.new.execute(tool: "list_services")

    services = UseCases::ListServicesUseCase.new.execute
    MCP::Tool::Response.new([ { type: "text", text: services.to_json } ])
  end
end

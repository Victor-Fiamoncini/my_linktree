class ListServicesTool < MCP::Tool
  tool_name "list_services"
  description "List the services Victor Fiamoncini offers."
  input_schema(properties: {})

  def self.call(**)
    RecordAgentConnectionUseCase.new.execute(tool: "list_services")

    services = ListServicesUseCase.new.execute(locale: :en)
    MCP::Tool::Response.new([ { type: "text", text: services.to_json } ])
  end
end

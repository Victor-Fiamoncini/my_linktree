class ListServicesTool < ApplicationTool
  tool_name "list_services"
  description "List the services Victor Fiamoncini offers."
  input_schema(properties: {})

  def self.perform(**)
    ListServicesUseCase.new.execute(locale: :en)
  end
end

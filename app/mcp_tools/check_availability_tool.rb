class CheckAvailabilityTool < ApplicationTool
  tool_name "check_availability"
  description "Check available meeting slots with Victor Fiamoncini."
  input_schema(properties: {})

  def self.perform(**)
    CheckAvailabilityUseCase.new.execute
  end
end

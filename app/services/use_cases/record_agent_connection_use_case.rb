module UseCases
  class RecordAgentConnectionUseCase
    def execute(tool:)
      AgentConnection.create!(tool: tool)
      nil
    end
  end
end

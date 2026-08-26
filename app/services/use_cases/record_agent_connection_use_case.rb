module UseCases
  class RecordAgentConnectionUseCase
    def initialize(connections: AgentConnection)
      @connections = connections
    end

    def execute(tool:)
      @connections.create!(tool: tool)
      nil
    end
  end
end

module UseCases
  class ListRecentConnectionsUseCase
    MAX_ENTRIES = 50

    def initialize(connections: AgentConnection)
      @connections = connections
    end

    def execute
      @connections.recent(MAX_ENTRIES).map { |connection| { tool: connection.tool, timestamp: connection.created_at.utc.iso8601(3) } }
    end
  end
end

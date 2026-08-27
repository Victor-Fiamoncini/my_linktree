module UseCases
  class ListRecentConnectionsUseCase
    def execute
      AgentConnection.recent.map { |connection| { tool: connection.tool, timestamp: connection.created_at.utc.iso8601(3) } }
    end
  end
end

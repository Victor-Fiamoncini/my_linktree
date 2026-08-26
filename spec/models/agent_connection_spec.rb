require "rails_helper"

RSpec.describe AgentConnection, type: :model do
  it "is valid with a tool name" do
    expect(AgentConnection.new(tool: "get_resume")).to be_valid
  end

  it "requires a tool name" do
    connection = AgentConnection.new

    expect(connection).not_to be_valid
    expect(connection.errors[:tool]).to be_present
  end

  describe ".recent" do
    it "returns the most recent entries first, capped at the given limit" do
      older = AgentConnection.create!(tool: "get_resume", created_at: 2.minutes.ago)
      newer = AgentConnection.create!(tool: "list_services", created_at: 1.minute.ago)

      expect(AgentConnection.recent(1)).to eq([ newer ])
      expect(AgentConnection.recent).to eq([ newer, older ])
    end
  end
end

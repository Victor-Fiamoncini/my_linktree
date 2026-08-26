require "rails_helper"

RSpec.describe UseCases::ListRecentConnectionsUseCase do
  it "returns recent connections as tool/timestamp hashes, newest first" do
    AgentConnection.create!(tool: "get_resume", created_at: 2.minutes.ago)
    AgentConnection.create!(tool: "schedule_meeting", created_at: 1.minute.ago)

    result = described_class.new.execute

    expect(result.map { |entry| entry[:tool] }).to eq(%w[schedule_meeting get_resume])
    expect(result.first[:timestamp]).to match(/\A\d{4}-\d{2}-\d{2}T/)
  end

  it "returns an empty array when there are no connections" do
    expect(described_class.new.execute).to eq([])
  end
end

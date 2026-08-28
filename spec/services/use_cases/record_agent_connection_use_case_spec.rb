require "rails_helper"

RSpec.describe UseCases::RecordAgentConnectionUseCase do
  it "creates an agent connection record for the given tool" do
    expect {
      described_class.new.execute(tool: "get_resume")
    }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("get_resume")
  end
end

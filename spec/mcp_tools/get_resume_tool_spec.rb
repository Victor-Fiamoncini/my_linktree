require "rails_helper"

RSpec.describe GetResumeTool do
  it "advertises the name and description the MCP server lists for agents" do
    expect(described_class.tool_name).to eq("get_resume")
    expect(described_class.description).to include("resume")
  end

  it "records the agent connection before answering" do
    expect { described_class.call }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("get_resume")
  end

  it "returns the profile as JSON text" do
    response = described_class.call

    expect(response.to_h[:isError]).to be_falsey
    payload = JSON.parse(response.content.first[:text], symbolize_names: true)
    expect(payload.keys).to contain_exactly(:name, :experiences, :education)
  end

  it "always answers in English, ignoring the caller's locale" do
    english = JSON.parse(described_class.call.content.first[:text])
    portuguese = I18n.with_locale(:"pt-BR") { JSON.parse(described_class.call.content.first[:text]) }

    expect(portuguese).to eq(english)
  end
end

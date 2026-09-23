require "rails_helper"

RSpec.describe ListServicesTool do
  it "advertises the name and description the MCP server lists for agents" do
    expect(described_class.tool_name).to eq("list_services")
    expect(described_class.description).to include("services")
  end

  it "records the agent connection before answering" do
    expect { described_class.call }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("list_services")
  end

  it "returns the services as JSON text" do
    response = described_class.call

    expect(response.to_h[:isError]).to be_falsey
    payload = JSON.parse(response.content.first[:text], symbolize_names: true)
    expect(payload).to all(include(:id, :name, :description))
  end

  it "always answers in English, ignoring the caller's locale" do
    english = JSON.parse(described_class.call.content.first[:text])
    portuguese = I18n.with_locale(:"pt-BR") { JSON.parse(described_class.call.content.first[:text]) }

    expect(portuguese).to eq(english)
  end
end

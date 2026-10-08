require "rails_helper"

RSpec.describe ApplicationTool do
  let(:tool) do
    Class.new(described_class) do
      tool_name "echo_tool"

      def self.perform(text: nil, **)
        raise ArgumentError, "Missing text" if text.nil?

        { echoed: text }
      end
    end
  end

  it "requires subclasses to implement .perform" do
    expect { described_class.perform }.to raise_error(NotImplementedError)
  end

  it "records the connection under the tool's name and answers with JSON" do
    response = nil

    expect { response = tool.call(text: "hi") }.to change { AgentConnection.where(tool: "echo_tool").count }.by(1)
    expect(response.content.first[:text]).to eq({ echoed: "hi" }.to_json)
    expect(response.error?).to be(false)
  end

  it "drops the server_context the MCP server passes" do
    expect(tool.call(text: "hi", server_context: { request: :ignored }).content.first[:text]).to eq({ echoed: "hi" }.to_json)
  end

  it "re-raises ArgumentError unless the subclass handles .rejected" do
    expect { tool.call }.to raise_error(ArgumentError, "Missing text")
  end

  it "answers with an error response when the subclass handles .rejected" do
    rejected = []
    tool.define_singleton_method(:rejected) { |error, **args| rejected << [ error.message, args ] }

    response = tool.call(other: 1)

    expect(response.error?).to be(true)
    expect(response.content.first[:text]).to eq("Missing text")
    expect(rejected).to eq([ [ "Missing text", { other: 1 } ] ])
  end
end

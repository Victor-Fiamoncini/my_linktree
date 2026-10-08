require "rails_helper"

RSpec.describe JsonRpcRequest do
  def build(body, method: "POST")
    described_class.new(ActionDispatch::Request.new(Rack::MockRequest.env_for("/api/mcp", method: method, input: body)))
  end

  let(:tool_call) do
    { jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "match_job", arguments: { job_description: "Rails role" } } }.to_json
  end

  it "reads the method, tool and arguments of a tool call" do
    rpc = build(tool_call)

    expect(rpc.method_name).to eq("tools/call")
    expect(rpc.tool).to eq("match_job")
    expect(rpc.arguments).to eq("job_description" => "Rails role")
  end

  it "matches a tool call by name" do
    rpc = build(tool_call)

    expect(rpc.tool_call?("match_job")).to be(true)
    expect(rpc.tool_call?("schedule_meeting")).to be(false)
  end

  it "does not treat other methods as tool calls" do
    rpc = build({ method: "tools/list", params: { name: "match_job" } }.to_json)

    expect(rpc.tool_call?("match_job")).to be(false)
  end

  it "rewinds the body so the transport can read it again" do
    request = ActionDispatch::Request.new(Rack::MockRequest.env_for("/api/mcp", method: "POST", input: tool_call))
    described_class.new(request).tool

    expect(request.body.read).to eq(tool_call)
  end

  it "ignores the body of a non-POST request" do
    expect(build(tool_call, method: "GET").method_name).to be_nil
  end

  it "treats malformed JSON as an empty payload" do
    rpc = build("{not json")

    expect(rpc.method_name).to be_nil
    expect(rpc.arguments).to eq({})
  end

  it "treats a non-object payload as empty" do
    expect(build("[1, 2]").method_name).to be_nil
  end

  it "treats a string where an object belongs as empty" do
    rpc = build({ method: "tools/call", params: "match_job" }.to_json)

    expect(rpc.tool).to be_nil
    expect(rpc.arguments).to eq({})
  end

  it "treats string arguments as empty" do
    rpc = build({ method: "tools/call", params: { name: "match_job", arguments: "oops" } }.to_json)

    expect(rpc.arguments).to eq({})
  end
end

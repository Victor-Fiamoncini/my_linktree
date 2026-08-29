require "rails_helper"

RSpec.describe "Api::Mcp", type: :request do
  # The mcp gem's DNS-rebinding protection only allows loopback Host headers by default;
  # Rails' request-spec default (www.example.com) gets rejected with 403.
  before { host! "127.0.0.1" }

  let(:headers) { { "Content-Type" => "application/json", "Accept" => "application/json, text/event-stream" } }

  def rpc(id:, method:, params: {})
    { jsonrpc: "2.0", id: id, method: method, params: params }.to_json
  end

  def call_tool(name, arguments = {}, id: 1)
    post "/api/mcp", params: rpc(id: id, method: "tools/call", params: { name: name, arguments: arguments }), headers: headers
    response.parsed_body
  end

  it "handles the initialize handshake" do
    post "/api/mcp",
      params: rpc(id: 1, method: "initialize", params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "rspec", version: "1.0" } }),
      headers: headers

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("result", "serverInfo", "name")).to eq("my_linktree")
  end

  it "lists all 4 tools" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"), headers: headers

    tool_names = response.parsed_body.dig("result", "tools").map { |t| t["name"] }
    expect(tool_names).to contain_exactly("get_resume", "list_services", "check_availability", "schedule_meeting")
  end

  it "calls get_resume and records the connection" do
    expect { call_tool("get_resume") }.to change(AgentConnection, :count).by(1)

    expect(AgentConnection.last.tool).to eq("get_resume")
  end

  it "calls list_services" do
    body = call_tool("list_services")

    text = body.dig("result", "content", 0, "text")
    expect(JSON.parse(text)).to be_an(Array)
  end

  it "calls check_availability" do
    body = call_tool("check_availability")

    text = JSON.parse(body.dig("result", "content", 0, "text"))
    expect(text["timezone"]).to eq("America/Sao_Paulo")
    expect(text["slots"]).to be_an(Array)
  end

  it "schedules a meeting successfully for a currently available slot" do
    availability = JSON.parse(call_tool("check_availability").dig("result", "content", 0, "text"))
    slot = availability["slots"].first

    body = call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slotStart: slot })

    expect(body.dig("result", "isError")).to be false
    booking = JSON.parse(body.dig("result", "content", 0, "text"))
    expect(booking["slotStart"]).to eq(slot)
  end

  it "returns isError true (not an HTTP error) for a double-booked slot" do
    availability = JSON.parse(call_tool("check_availability").dig("result", "content", 0, "text"))
    slot = availability["slots"].first
    call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slotStart: slot })

    body = call_tool("schedule_meeting", { name: "Bob", email: "bob@example.com", slotStart: slot })

    expect(response).to have_http_status(:ok)
    expect(body.dig("result", "isError")).to be true
    expect(body.dig("result", "content", 0, "text")).to eq("Slot unavailable")
  end

  it "returns isError true for missing required fields" do
    body = call_tool("schedule_meeting", { name: "Bob" })

    expect(response).to have_http_status(:ok)
    expect(body.dig("result", "isError")).to be true
    expect(body.dig("result", "content", 0, "text")).to eq("Missing required fields")
  end

  it "rate limits general tool calls after 30 requests from the same IP" do
    ip_headers = headers.merge("X-Forwarded-For" => "9.9.9.9")

    30.times do |i|
      post "/api/mcp", params: rpc(id: i, method: "tools/list"), headers: ip_headers
      expect(response).to have_http_status(:ok)
    end

    post "/api/mcp", params: rpc(id: 31, method: "tools/list"), headers: ip_headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "rate limits schedule_meeting specifically after 3 requests from the same IP" do
    ip_headers = headers.merge("X-Forwarded-For" => "8.8.8.8")

    3.times do
      post "/api/mcp",
        params: rpc(id: 1, method: "tools/call", params: { name: "schedule_meeting", arguments: { name: "X", email: "x@x.com", slotStart: "2099-01-01T00:00:00.000Z" } }),
        headers: ip_headers
      expect(response).to have_http_status(:ok)
    end

    post "/api/mcp",
      params: rpc(id: 1, method: "tools/call", params: { name: "schedule_meeting", arguments: { name: "X", email: "x@x.com", slotStart: "2099-01-01T00:00:00.000Z" } }),
      headers: ip_headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "rate limits by the real connection IP when no X-Forwarded-For header is present" do
    30.times do |i|
      post "/api/mcp", params: rpc(id: i, method: "tools/list"), headers: headers
      expect(response).to have_http_status(:ok)
    end

    post "/api/mcp", params: rpc(id: 31, method: "tools/list"), headers: headers
    expect(response).to have_http_status(:too_many_requests)
  end

  it "sets permissive CORS headers on a JSON-RPC response" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"), headers: headers

    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
  end

  it "answers an OPTIONS preflight with 200 and CORS headers, without touching the MCP server" do
    options "/api/mcp"

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("*")
    expect(response.headers["Access-Control-Allow-Methods"]).to include("POST")
  end

  it "answers a GET with a plain server description instead of the gem's 405" do
    get "/api/mcp"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["tools"]).to contain_exactly("get_resume", "list_services", "check_availability", "schedule_meeting")
  end

  it "accepts the bare apex host in addition to the canonical www host" do
    host! "victorfiamon.com.br"

    post "/api/mcp", params: rpc(id: 1, method: "tools/list"), headers: headers

    expect(response).to have_http_status(:ok)
  end
end

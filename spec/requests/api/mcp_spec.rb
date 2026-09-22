require "rails_helper"

RSpec.describe "Api::Mcp", type: :request do
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

  it "includes server icons/title/websiteUrl when the client negotiates a protocol version newer than 2025-06-18" do
    post "/api/mcp",
      params: rpc(id: 1, method: "initialize", params: { protocolVersion: "2025-11-25", capabilities: {}, clientInfo: { name: "rspec", version: "1.0" } }),
      headers: headers

    server_info = response.parsed_body.dig("result", "serverInfo")
    expect(server_info["title"]).to eq(SeoConfig::SITE_NAME)
    expect(server_info["websiteUrl"]).to eq(SeoConfig::SITE_URL)
    expect(server_info["icons"]).to contain_exactly(
      { "mimeType" => "image/png", "sizes" => "192x192", "src" => SeoConfig::MCP_ICON_192 },
      { "mimeType" => "image/png", "sizes" => "512x512", "src" => SeoConfig::MCP_ICON_512 }
    )
  end

  it "omits icons/title/websiteUrl for the legacy 2025-06-18 handshake (documents the gem's version gate)" do
    post "/api/mcp",
      params: rpc(id: 1, method: "initialize", params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "rspec", version: "1.0" } }),
      headers: headers

    server_info = response.parsed_body.dig("result", "serverInfo")
    expect(server_info).not_to have_key("icons")
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

  it "returns get_resume/list_services content in English regardless of the caller's Accept-Language" do
    pt_headers = headers.merge("Accept-Language" => "pt-BR")

    post "/api/mcp", params: rpc(id: 1, method: "tools/call", params: { name: "get_resume", arguments: {} }), headers: pt_headers
    resume = JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))

    post "/api/mcp", params: rpc(id: 2, method: "tools/call", params: { name: "list_services", arguments: {} }), headers: pt_headers
    services = JSON.parse(response.parsed_body.dig("result", "content", 0, "text"))

    expect(resume["experiences"].first["role"]).to eq("Fullstack Software Engineer")
    expect(services.first["name"]).to eq("Frontend & Backend Software Development")
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

    body = call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slot_start: slot })

    expect(body.dig("result", "isError")).to be false
    booking = JSON.parse(body.dig("result", "content", 0, "text"))
    expect(booking["slot_start"]).to eq(slot)
  end

  it "returns isError true (not an HTTP error) for a double-booked slot" do
    availability = JSON.parse(call_tool("check_availability").dig("result", "content", 0, "text"))
    slot = availability["slots"].first
    call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slot_start: slot })

    body = call_tool("schedule_meeting", { name: "Bob", email: "bob@example.com", slot_start: slot })

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

  describe "structured events" do
    it "reports one mcp.request event per JSON-RPC call, naming the tool and its duration" do
      events = captured_events { call_tool("get_resume") }

      event = find_event(events, "mcp.request")
      expect(event[:payload]).to include(jsonrpc_method: "tools/call", tool: "get_resume", failure: nil)
      expect(event[:payload][:duration_ms]).to be_a(Numeric)
      expect(event[:tags]).to eq(mcp: true)
    end

    it "carries the client name from the initialize handshake" do
      events = captured_events do
        post "/api/mcp",
          params: rpc(id: 1, method: "initialize", params: { protocolVersion: "2025-06-18", capabilities: {}, clientInfo: { name: "rspec", version: "1.0" } }),
          headers: headers
      end

      expect(find_event(events, "mcp.request")[:payload]).to include(jsonrpc_method: "initialize", client_name: "rspec")
    end

    it "attaches the request context every event inherits" do
      events = captured_events { call_tool("list_services") }

      expect(find_event(events, "mcp.request")[:context]).to include(:request_id, :ip, path: "/api/mcp")
    end

    it "reports mcp.meeting.booked with the contact redacted" do
      availability = JSON.parse(call_tool("check_availability").dig("result", "content", 0, "text"))
      slot = availability["slots"].first

      events = captured_events do
        call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slot_start: slot })
      end

      payload = find_event(events, "mcp.meeting.booked")[:payload]
      expect(payload).to include(slot_start: slot, has_company: false, contact_domain: "example.com")
      expect(payload[:contact_digest]).to match(/\A[0-9a-f]{12}\z/)
      expect(payload.to_json).not_to include("jane@example.com")
    end

    it "reports mcp.meeting.rejected for a double-booked slot, which the HTTP status cannot show" do
      availability = JSON.parse(call_tool("check_availability").dig("result", "content", 0, "text"))
      slot = availability["slots"].first
      call_tool("schedule_meeting", { name: "Jane", email: "jane@example.com", slot_start: slot })

      events = captured_events do
        call_tool("schedule_meeting", { name: "Bob", email: "bob@example.com", slot_start: slot })
      end

      expect(response).to have_http_status(:ok)
      expect(find_event(events, "mcp.meeting.rejected")[:payload]).to include(
        severity: "warn", reason: "Slot unavailable", slot_start: slot, contact_domain: "example.com"
      )
    end

    # Pre-existing behaviour, pinned here because the event now makes it visible: a body that
    # isn't valid JSON blows up in Rails' params parsing (ApplicationController#switch_locale
    # reads params[:locale]) long before the transport sees it, so it lands on rescue_from
    # StandardError as a 500 rather than a 400.
    it "reports api.error for a body that isn't valid JSON" do
      events = captured_events { post "/api/mcp", params: "not json at all", headers: headers }

      expect(response).to have_http_status(:internal_server_error)
      expect(find_event(events, "api.error")[:payload]).to include(
        error_class: "ActionDispatch::Http::Parameters::ParseError"
      )
      expect(find_event(events, "api.rate_limited")).to be_nil
    end

    it "lets the transport reject a body that is valid JSON but not an object" do
      events = captured_events { post "/api/mcp", params: "[1, 2, 3]", headers: headers }

      expect(response).to have_http_status(:bad_request)
      expect(find_event(events, "api.error")).to be_nil
      expect(find_event(events, "api.rate_limited")).to be_nil
    end

    it "names the throttled tool on the rate-limit event" do
      ip_headers = headers.merge("X-Forwarded-For" => "7.7.7.7")
      arguments = { name: "X", email: "x@x.com", slot_start: "2099-01-01T00:00:00.000Z" }
      params = rpc(id: 1, method: "tools/call", params: { name: "schedule_meeting", arguments: arguments })

      3.times { post "/api/mcp", params: params, headers: ip_headers }

      events = captured_events { post "/api/mcp", params: params, headers: ip_headers }

      expect(response).to have_http_status(:too_many_requests)
      expect(find_event(events, "api.rate_limited")[:payload]).to include(
        severity: "warn", jsonrpc_method: "tools/call", tool: "schedule_meeting"
      )
    end
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
        params: rpc(id: 1, method: "tools/call", params: { name: "schedule_meeting", arguments: { name: "X", email: "x@x.com", slot_start: "2099-01-01T00:00:00.000Z" } }),
        headers: ip_headers
      expect(response).to have_http_status(:ok)
    end

    post "/api/mcp",
      params: rpc(id: 1, method: "tools/call", params: { name: "schedule_meeting", arguments: { name: "X", email: "x@x.com", slot_start: "2099-01-01T00:00:00.000Z" } }),
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

  it "does not advertise an Access-Control-Allow-Origin when no Origin header is sent" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"), headers: headers

    expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
  end

  it "reflects back an allowed Origin (canonical www host) and lets the transport allow it through" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"),
      headers: headers.merge("Origin" => "https://www.victorfiamon.com.br")

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://www.victorfiamon.com.br")
    expect(response.headers["Vary"]).to eq("Origin")
  end

  it "reflects back an allowed Origin (bare apex host) and lets the transport allow it through" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"),
      headers: headers.merge("Origin" => "https://victorfiamon.com.br")

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://victorfiamon.com.br")
  end

  it "reflects back an arbitrary Origin (e.g. an AI agent client's) and lets the transport allow it through" do
    post "/api/mcp", params: rpc(id: 1, method: "tools/list"),
      headers: headers.merge("Origin" => "https://claude.ai")

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://claude.ai")
    expect(response.headers["Vary"]).to eq("Origin")
  end

  it "answers an OPTIONS preflight with 200 and CORS method/header advertisements, without touching the MCP server" do
    options "/api/mcp"

    expect(response).to have_http_status(:ok)
    expect(response.headers["Access-Control-Allow-Methods"]).to include("POST", "GET", "DELETE", "OPTIONS")
  end

  it "answers a DELETE with the transport's stateless-mode success response" do
    delete "/api/mcp"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["success"]).to be true
  end

  it "answers a GET with a plain server description instead of the gem's 405" do
    get "/api/mcp"

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["tools"]).to contain_exactly("get_resume", "list_services", "check_availability", "schedule_meeting")
  end

  it "answers a stream-opening GET (Accept: text/event-stream) with the gem's native 405, not the plain description" do
    get "/api/mcp", headers: { "Accept" => "text/event-stream" }

    expect(response).to have_http_status(:method_not_allowed)
    expect(response.parsed_body.dig("error", "message")).to eq("Method not allowed")
  end

  it "accepts the bare apex host in addition to the canonical www host" do
    host! "victorfiamon.com.br"

    post "/api/mcp", params: rpc(id: 1, method: "tools/list"), headers: headers

    expect(response).to have_http_status(:ok)
  end
end

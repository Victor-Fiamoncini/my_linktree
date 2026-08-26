class ScheduleMeetingTool < MCP::Tool
  tool_name "schedule_meeting"
  description "Schedule a meeting with Victor Fiamoncini for an available slot returned by check_availability."
  input_schema(
    properties: {
      name: { type: "string" },
      email: { type: "string" },
      company: { type: "string" },
      slotStart: { type: "string" }
    }
  )

  def self.call(name: nil, email: nil, company: nil, slotStart: nil, **)
    UseCases::RecordAgentConnectionUseCase.new.execute(tool: "schedule_meeting")

    booking = UseCases::ScheduleMeetingUseCase.new.execute(name: name, email: email, company: company, slot_start: slotStart)

    payload = { name: booking[:name], email: booking[:email], company: booking[:company], slotStart: booking[:slot_start] }
    MCP::Tool::Response.new([ { type: "text", text: payload.to_json } ])
  rescue ApplicationError => e
    MCP::Tool::Response.new([ { type: "text", text: e.message } ], error: true)
  end
end

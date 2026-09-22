class ScheduleMeetingTool < MCP::Tool
  tool_name "schedule_meeting"
  description "Schedule a meeting with Victor Fiamoncini for an available slot returned by check_availability."
  input_schema(
    properties: {
      name: { type: "string" },
      email: { type: "string" },
      company: { type: "string" },
      slot_start: { type: "string" }
    }
  )

  def self.call(name: nil, email: nil, company: nil, slot_start: nil, **)
    UseCases::RecordAgentConnectionUseCase.new.execute(tool: "schedule_meeting")

    booking = UseCases::ScheduleMeetingUseCase.new.execute(name: name, email: email, company: company, slot_start: slot_start)

    Rails.event.notify(
      "mcp.meeting.booked",
      slot_start: booking[:slot_start],
      has_company: booking[:company].present?,
      **LogRedaction.contact(booking[:email])
    )

    payload = { name: booking[:name], email: booking[:email], company: booking[:company], slot_start: booking[:slot_start] }
    MCP::Tool::Response.new([ { type: "text", text: payload.to_json } ])
  rescue ArgumentError => e
    # isError: true at HTTP 200 reaches neither rescue_from nor the gem's exception reporter, so
    # without this a double-booked slot or a missing field leaves no trace at all.
    Rails.event.notify(
      "mcp.meeting.rejected",
      severity: "warn",
      reason: e.message,
      slot_start: slot_start,
      **LogRedaction.contact(email)
    )

    MCP::Tool::Response.new([ { type: "text", text: e.message } ], error: true)
  end
end

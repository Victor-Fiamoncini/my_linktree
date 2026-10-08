class ScheduleMeetingTool < ApplicationTool
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

  def self.perform(name: nil, email: nil, company: nil, slot_start: nil, **)
    booking = ScheduleMeetingUseCase.new.execute(name: name, email: email, company: company, slot_start: slot_start)

    Rails.event.notify(
      "mcp.meeting.booked",
      slot_start: booking[:slot_start],
      has_company: booking[:company].present?,
      **LogRedaction.contact(booking[:email])
    )

    booking.slice(:name, :email, :company, :slot_start)
  end

  def self.rejected(error, email: nil, slot_start: nil, **)
    Rails.event.notify(
      "mcp.meeting.rejected",
      severity: "warn",
      reason: error.message,
      slot_start: slot_start,
      **LogRedaction.contact(email)
    )
  end
end

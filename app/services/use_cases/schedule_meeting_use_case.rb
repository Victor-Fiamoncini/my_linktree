module UseCases
  class ScheduleMeetingUseCase
    def initialize(check_availability_use_case: CheckAvailabilityUseCase.new)
      @check_availability_use_case = check_availability_use_case
    end

    def execute(name:, email:, slot_start:, company: nil)
      raise MissingRequiredFieldsError if name.blank? || email.blank? || slot_start.blank?

      available_slots = @check_availability_use_case.execute[:slots]
      raise SlotUnavailableError unless available_slots.include?(slot_start)

      booking = Booking.new(name: name, email: email, company: company, slot_start: slot_start)

      begin
        raise SlotUnavailableError unless booking.save
      rescue ActiveRecord::RecordNotUnique
        raise SlotUnavailableError
      end

      MeetingMailer.confirmation(name: name, email: email, slot_start: slot_start).deliver_now
      MeetingMailer.notification(name: name, email: email, company: company, slot_start: slot_start).deliver_now

      { name: name, email: email, company: company, slot_start: slot_start }
    end
  end
end

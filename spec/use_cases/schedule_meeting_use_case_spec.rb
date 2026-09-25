require "rails_helper"

RSpec.describe ScheduleMeetingUseCase do
  let(:slot_start) { "2027-03-03T12:00:00.000Z" }
  let(:check_availability_use_case) { instance_double(CheckAvailabilityUseCase, execute: { timezone: "UTC", slots: [ slot_start ] }) }
  let(:use_case) { described_class.new(check_availability_use_case: check_availability_use_case) }

  it "books the slot and sends confirmation + notification emails" do
    expect {
      perform_enqueued_jobs do
        result = use_case.execute(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

        expect(result).to eq(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)
      end
    }.to change(Booking, :count).by(1).and change { ActionMailer::Base.deliveries.size }.by(2)

    subjects = ActionMailer::Base.deliveries.last(2).map(&:subject)
    expect(subjects).to eq([ "My Linktree - Meeting scheduled", "My Linktree - New meeting booked by Jane" ])
  end

  it "enqueues confirmation and notification mailer jobs with the given params" do
    use_case.execute(name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start)

    assert_enqueued_email_with MeetingMailer, :confirmation,
      args: [ { name: "Jane", email: "jane@example.com", slot_start: slot_start } ]
    assert_enqueued_email_with MeetingMailer, :notification,
      args: [ { name: "Jane", email: "jane@example.com", company: "Acme", slot_start: slot_start } ]
  end

  it "raises ArgumentError when a required field is missing" do
    expect {
      use_case.execute(name: "", email: "jane@example.com", slot_start: slot_start)
    }.to raise_error(ArgumentError, "Missing required fields")
  end

  it "raises ArgumentError when the slot isn't currently available" do
    expect {
      use_case.execute(name: "Jane", email: "jane@example.com", slot_start: "2099-01-01T00:00:00.000Z")
    }.to raise_error(ArgumentError, "Slot unavailable")
  end

  it "raises ArgumentError when the slot was booked before this request validated" do
    Booking.create!(name: "Bob", email: "bob@example.com", slot_start: slot_start)

    expect {
      use_case.execute(name: "Jane", email: "jane@example.com", slot_start: slot_start)
    }.to raise_error(ArgumentError, "Slot unavailable")
  end

  # The case above is caught by the uniqueness validation, which runs a SELECT. Two requests that
  # validate concurrently both pass it, and only the unique index on slot_start rejects the loser
  # — so this is the one double-booking path the validation cannot see.
  it "turns a lost insert race into the same domain error, not a 500" do
    racing_booking = Booking.new(name: "Jane", email: "jane@example.com", slot_start: slot_start)
    allow(racing_booking).to receive(:save).and_raise(ActiveRecord::RecordNotUnique, "PG::UniqueViolation")
    allow(Booking).to receive(:new).and_return(racing_booking)

    expect {
      expect {
        use_case.execute(name: "Jane", email: "jane@example.com", slot_start: slot_start)
      }.to raise_error(ArgumentError, "Slot unavailable")
    }.not_to change(Booking, :count)

    # A booking that lost the race must not tell the person it succeeded.
    assert_no_enqueued_emails
  end
end

require "rails_helper"

RSpec.describe UseCases::ScheduleMeetingUseCase do
  let(:slot_start) { "2027-03-03T12:00:00.000Z" }
  let(:check_availability_use_case) { instance_double(UseCases::CheckAvailabilityUseCase, execute: { timezone: "UTC", slots: [ slot_start ] }) }
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

  it "raises ArgumentError on a double-booking race" do
    Booking.create!(name: "Bob", email: "bob@example.com", slot_start: slot_start)

    expect {
      use_case.execute(name: "Jane", email: "jane@example.com", slot_start: slot_start)
    }.to raise_error(ArgumentError, "Slot unavailable")
  end
end

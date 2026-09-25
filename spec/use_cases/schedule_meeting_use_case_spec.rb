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

  # The example above stubs the collision; this one runs four real threads against real Postgres.
  # Three rounds, not one, on purpose: the first round's connections are cold enough to stagger the
  # threads, so the validation's SELECT catches every loser and the unique index is never reached.
  # From the second round on the threads land together and the index does the rejecting — which is
  # the branch this exists to cover. Measured: round 1 always 0 index hits, rounds 2+ always 3.
  describe "four visitors booking the same slot at once" do
    self.use_transactional_tests = false

    after { Booking.delete_all }

    it "lets exactly one win each round and hands the rest the domain error, never a 500" do
      availability = Struct.new(:slots) do
        def execute
          { timezone: "UTC", slots: slots }
        end
      end

      3.times do |round|
        slot = (Time.utc(2029, 1, 1) + round.days).iso8601(3)
        concurrent_use_case = described_class.new(check_availability_use_case: availability.new([ slot ]))
        latch = Concurrent::CountDownLatch.new(1)

        threads = 4.times.map do |index|
          Thread.new do
            ActiveRecord::Base.connection_pool.with_connection do
              latch.wait

              # Only ArgumentError is caught, so any other class propagates through #value and
              # fails the example by name — that is the "never a 500" assertion.
              begin
                concurrent_use_case.execute(name: "User #{index}", email: "u#{index}@example.com", slot_start: slot)
                :booked
              rescue ArgumentError => error
                error.message
              end
            end
          end
        end

        latch.count_down
        outcomes = threads.map(&:value)

        expect(outcomes.count(:booked)).to eq(1), "round #{round}: #{outcomes.inspect}"
        expect(outcomes.count("Slot unavailable")).to eq(3), "round #{round}: #{outcomes.inspect}"
        expect(Booking.where(slot_start: slot).count).to eq(1)
      end

      assert_enqueued_emails 6
    end
  end
end

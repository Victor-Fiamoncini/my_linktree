require "rails_helper"

RSpec.describe Booking, type: :model do
  it "is valid with name, email, and slot_start" do
    booking = Booking.new(name: "Jane", email: "jane@example.com", slot_start: 1.day.from_now)

    expect(booking).to be_valid
  end

  it "requires name, email, and slot_start" do
    booking = Booking.new

    expect(booking).not_to be_valid
    expect(booking.errors[:name]).to be_present
    expect(booking.errors[:email]).to be_present
    expect(booking.errors[:slot_start]).to be_present
  end

  it "does not require company" do
    booking = Booking.new(name: "Jane", email: "jane@example.com", slot_start: 1.day.from_now, company: nil)

    expect(booking).to be_valid
  end

  it "rejects a malformed email" do
    booking = Booking.new(name: "Jane", email: "not-an-email", slot_start: 1.day.from_now)

    expect(booking).not_to be_valid
    expect(booking.errors[:email]).to be_present
  end

  it "rejects a name longer than 255 characters" do
    booking = Booking.new(name: "a" * 256, email: "jane@example.com", slot_start: 1.day.from_now)

    expect(booking).not_to be_valid
    expect(booking.errors[:name]).to be_present
  end

  it "prevents two bookings for the same slot_start" do
    slot_start = 1.day.from_now.change(usec: 0)
    Booking.create!(name: "Jane", email: "jane@example.com", slot_start: slot_start)

    duplicate = Booking.new(name: "Bob", email: "bob@example.com", slot_start: slot_start)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:slot_start]).to include("has already been taken")
  end

  it "enforces uniqueness at the database level too" do
    slot_start = 1.day.from_now.change(usec: 0)
    Booking.create!(name: "Jane", email: "jane@example.com", slot_start: slot_start)

    duplicate = Booking.new(name: "Bob", email: "bob@example.com", slot_start: slot_start)

    expect { duplicate.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  describe ".upcoming" do
    it "returns bookings within the given range" do
      inside = Booking.create!(name: "Jane", email: "jane@example.com", slot_start: 2.days.from_now)
      Booking.create!(name: "Bob", email: "bob@example.com", slot_start: 30.days.from_now)

      result = Booking.upcoming(from: Time.current, to: 5.days.from_now)

      expect(result).to contain_exactly(inside)
    end
  end
end

require "rails_helper"

RSpec.describe UseCases::CheckAvailabilityUseCase do
  # 2027-03-03 08:00 UTC is a Wednesday (wday 3), both in UTC and in America/Sao_Paulo (UTC-3).
  let(:frozen_time) { Time.utc(2027, 3, 3, 8, 0, 0) }
  let(:availability_config) do
    {
      timezone: "America/Sao_Paulo",
      slot_duration_minutes: 60,
      booking_horizon_days: 3,
      weekly_windows: [ { weekday: 3, start: "09:00", end: "12:00" } ]
    }
  end

  around { |example| travel_to(frozen_time) { example.run } }

  it "returns one-hour slots for a 09:00-12:00 window, converted to UTC" do
    result = described_class.new(availability_config: availability_config).execute

    expect(result[:timezone]).to eq("America/Sao_Paulo")
    expect(result[:slots]).to eq(
      [
        "2027-03-03T12:00:00.000Z",
        "2027-03-03T13:00:00.000Z",
        "2027-03-03T14:00:00.000Z"
      ]
    )
  end

  it "excludes already booked slots" do
    Booking.create!(name: "Jane", email: "jane@example.com", slot_start: "2027-03-03T13:00:00.000Z")

    result = described_class.new(availability_config: availability_config).execute

    expect(result[:slots]).to eq(%w[2027-03-03T12:00:00.000Z 2027-03-03T14:00:00.000Z])
  end

  it "excludes days that don't match any weekly window" do
    config = availability_config.merge(weekly_windows: [ { weekday: 6, start: "09:00", end: "12:00" } ])

    result = described_class.new(availability_config: config).execute

    expect(result[:slots]).to eq([])
  end
end

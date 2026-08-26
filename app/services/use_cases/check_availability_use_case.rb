module UseCases
  class CheckAvailabilityUseCase
    def initialize(availability_config: Rails.application.config_for(:availability), bookings: Booking)
      @availability_config = availability_config
      @bookings = bookings
    end

    def execute
      zone = ActiveSupport::TimeZone[@availability_config[:timezone]]
      slot_duration = @availability_config[:slot_duration_minutes]
      windows = @availability_config[:weekly_windows]
      horizon_days = @availability_config[:booking_horizon_days]

      now = Time.current
      today = now.in_time_zone(zone).to_date
      horizon_end = zone.parse("#{today + horizon_days} 23:59")

      booked_slots = @bookings.where(slot_start: now..horizon_end).pluck(:slot_start).map { |t| to_iso(t) }.to_set

      slots = []

      horizon_days.times do |day_offset|
        date = today + day_offset
        weekday = date.wday
        day_windows = windows.select { |window| window[:weekday] == weekday }

        day_windows.each do |window|
          start_minutes = parse_time_to_minutes(window[:start])
          end_minutes = parse_time_to_minutes(window[:end])

          minutes = start_minutes
          while minutes + slot_duration <= end_minutes
            slot_start = zone.parse("#{date} #{minutes_to_time_string(minutes)}")
            slot_start_iso = to_iso(slot_start)

            slots << slot_start_iso unless slot_start <= now || booked_slots.include?(slot_start_iso)

            minutes += slot_duration
          end
        end
      end

      { timezone: @availability_config[:timezone], slots: slots }
    end

    private

    def to_iso(time)
      time.utc.iso8601(3)
    end

    def parse_time_to_minutes(time_string)
      hours, minutes = time_string.split(":").map(&:to_i)
      hours * 60 + minutes
    end

    def minutes_to_time_string(minutes)
      format("%02d:%02d", minutes / 60, minutes % 60)
    end
  end
end

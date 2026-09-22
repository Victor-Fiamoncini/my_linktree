require "active_support/event_reporter/test_helper"

# Captures what the app reports through Rails.event while the block runs, so specs don't care
# which subscriber ships it in production.
module EventReporterHelper
  def captured_events
    subscriber = ActiveSupport::EventReporter::TestHelper::EventSubscriber.new

    Rails.event.subscribe(subscriber)

    begin
      yield
    ensure
      Rails.event.unsubscribe(subscriber)
    end

    subscriber.events
  end

  def find_event(events, name)
    events.find { |event| event[:name] == name }
  end
end

RSpec.configure do |config|
  config.include EventReporterHelper
end

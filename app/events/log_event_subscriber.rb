# The local counterpart to the subscriber logtail-rails registers in production, so the same
# events are readable in the development log and assertable in specs.
class LogEventSubscriber
  def emit(event)
    payload = event[:payload].presence || {}
    tags = event[:tags].presence

    Rails.logger.info("[#{event[:name]}] #{payload.to_json}#{" tags=#{tags.to_json}" if tags}")
  end
end

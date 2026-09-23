# Local counterpart to the subscriber logtail-rails registers in production.
class LogEventSubscriber
  def emit(event)
    payload = event[:payload].presence || {}
    tags = event[:tags].presence

    Rails.logger.info("[#{event[:name]}] #{payload.to_json}#{" tags=#{tags.to_json}" if tags}")
  end
end

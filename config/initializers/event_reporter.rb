# frozen_string_literal: true

# Production forwards events to Better Stack through the subscriber that
# `Logtail::Logger.create_default_logger` registers (config/environments/production.rb).
# Everywhere else, register a plain one so `Rails.event.notify` calls land in the local log
# instead of vanishing — Rails ships no default subscriber.
#
# The filter keeps it to this app's own events: Rails 8.1 emits framework events
# (action_controller.request_started, active_record.sql, ...) through the same reporter as soon
# as any subscriber exists, and locally those only duplicate lines Rails already prints. Matching
# on source location means new app events need no registration here.
#
# `after_initialize` because app/ constants aren't autoloadable from an initializer. The
# subscriber therefore outlives reloads — editing it needs a server restart.
Rails.application.config.after_initialize do
  next if Rails.logger.is_a?(Logtail::Logger)

  app_root = Rails.root.to_s

  Rails.event.subscribe(LogEventSubscriber.new) do |event|
    event.dig(:source_location, :filepath)&.start_with?(app_root)
  end
end

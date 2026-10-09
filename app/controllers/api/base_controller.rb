module Api
  class BaseController < ApplicationController
    # Log class + message, not the exception — the default formatter drops both.
    rescue_from StandardError do |e|
      Rails.logger.error("#{e.class}: #{e.message}")

      render_error :internal_server_error, "#{event_namespace}.error", internal_server_error_body,
        severity: "error", error_class: e.class.name, error_message: e.message, backtrace: e.backtrace&.first(5)
    end

    rescue_from ActionDispatch::Http::Parameters::ParseError do
      render json: { message: "Malformed request body" }, status: :bad_request
    end

    rescue_from ActionController::TooManyRequests do
      render_error :too_many_requests, "#{event_namespace}.rate_limited", too_many_requests_body, **rate_limited_event_payload
    end

    private

    def render_error(status, event, body, severity: "warn", **payload)
      Rails.event.notify(event, severity:, **payload)

      render json: body, status:
    end

    # Subclasses extend this instead of overriding the handler, which would emit a second event.
    def rate_limited_event_payload
      {}
    end

    def event_namespace
      raise NotImplementedError
    end

    def internal_server_error_body
      raise NotImplementedError
    end

    def too_many_requests_body
      raise NotImplementedError
    end
  end
end

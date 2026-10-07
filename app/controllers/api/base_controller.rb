module Api
  class BaseController < ApplicationController
    rescue_from StandardError, with: :render_internal_server_error
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    private

    # Log class + message, not the exception — the default formatter drops boths.
    def render_internal_server_error(e)
      Rails.logger.error("#{e.class}: #{e.message}")

      Rails.event.notify(
        "#{event_namespace}.error",
        severity: "error",
        error_class: e.class.name,
        error_message: e.message,
        backtrace: e.backtrace&.first(5)
      )

      render json: internal_server_error_body, status: :internal_server_error
    end

    def render_bad_request
      render json: { message: "Malformed request body" }, status: :bad_request
    end

    def render_too_many_requests
      Rails.event.notify("#{event_namespace}.rate_limited", **rate_limited_event_payload)

      render json: too_many_requests_body, status: :too_many_requests
    end

    # Subclasses extend this instead of overriding the handler, which would emit a second event.
    def rate_limited_event_payload
      { severity: "warn" }
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

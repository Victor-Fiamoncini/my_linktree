module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    rescue_from StandardError, with: :render_internal_server_error
    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    private

    # Log the class and message, not the exception object — the default formatter just calls #to_s,
    # which drops both the class and the backtrace.
    def render_internal_server_error(e)
      Rails.logger.error("#{e.class}: #{e.message}")

      Rails.event.notify(
        "api.error",
        severity: "error",
        error_class: e.class.name,
        error_message: e.message,
        backtrace: e.backtrace&.first(5)
      )

      render json: { message: "Internal Server Error", action: "Please contact the administrator of the application." }, status: :internal_server_error
    end

    def render_too_many_requests
      Rails.event.notify("api.rate_limited", **rate_limited_event_payload)

      render json: { message: "Too many requests", action: "Please wait a moment before trying again." }, status: :too_many_requests
    end

    # Subclasses extend this instead of overriding the handler, which would emit a second event.
    def rate_limited_event_payload
      { severity: "warn", controller: controller_name, action: action_name }
    end
  end
end

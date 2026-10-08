module Api
  class FormController < BaseController
    rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

    private

    def render_invalid_authenticity_token
      Rails.event.notify("#{event_namespace}.csrf_rejected", severity: "warn")

      render json: { message: localized(:invalid_authenticity_token) }, status: :unprocessable_content
    end

    def internal_server_error_body
      { message: localized(:internal_error) }
    end

    def too_many_requests_body
      { message: localized(:too_many_requests) }
    end

    def localized(key)
      t("#{controller_name}.#{key}", locale: request_locale)
    end
  end
end

module Api
  class FormController < BaseController
    rescue_from ActionController::InvalidAuthenticityToken do
      render_error :unprocessable_content, "#{event_namespace}.csrf_rejected", { message: localized(:invalid_authenticity_token) }
    end

    private

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

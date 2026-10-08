module Api
  class PublicController < BaseController
    skip_before_action :verify_authenticity_token

    private

    def event_namespace
      "api"
    end

    def internal_server_error_body
      { message: "Internal Server Error", action: "Please contact the administrator of the application." }
    end

    def too_many_requests_body
      { message: "Too many requests", action: "Please wait a moment before trying again." }
    end

    def rate_limited_event_payload
      super.merge(controller: controller_name, action: action_name)
    end
  end
end

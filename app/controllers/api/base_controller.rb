module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    rescue_from StandardError, with: :render_internal_server_error

    private

    def render_internal_server_error(e)
      Rails.logger.error(e)

      render json: { message: "Internal Server Error", action: "Please contact the administrator of the application." },
             status: :internal_server_error
    end
  end
end

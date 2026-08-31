module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    rescue_from StandardError, with: :render_internal_server_error
    rescue_from ActionController::TooManyRequests, with: :render_too_many_requests

    private

    def render_internal_server_error(e)
      Rails.logger.error(e)

      render json: { message: "Internal Server Error", action: "Please contact the administrator of the application." }, status: :internal_server_error
    end

    def render_too_many_requests
      render json: { message: "Too many requests", action: "Please wait a moment before trying again." }, status: :too_many_requests
    end
  end
end

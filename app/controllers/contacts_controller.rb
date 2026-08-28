class ContactsController < ApplicationController
  rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

  rescue_from StandardError, with: :render_internal_error
  rescue_from UseCases::SendContactEmailUseCase::ValidationError, with: :render_validation_error
  rescue_from ActionController::TooManyRequests, with: :render_too_many_requests
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

  def create
    UseCases::SendContactEmailUseCase.new.execute(**contact_params)

    render json: { message: "Thank you for your message! I'll get back to you as soon as possible." }, status: :ok
  end

  private

  def contact_params
    params.permit(:name, :email, :message).to_h.symbolize_keys
  end

  def render_validation_error(e)
    render json: { message: "Check the highlighted fields and try again.", errors: e.errors }, status: :unprocessable_content
  end

  def render_too_many_requests
    render json: { message: "Too many requests. Please wait a moment before trying again." }, status: :too_many_requests
  end

  def render_invalid_authenticity_token
    render json: { message: "Your session expired. Please refresh the page and try again." }, status: :unprocessable_content
  end

  def render_internal_error(e)
    Rails.logger.error(e)
    render json: { message: "Internal Server Error", action: "Please contact the administrator of the application." }, status: :internal_server_error
  end
end

class ContactsController < ApplicationController
  rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

  rescue_from StandardError, with: :render_internal_error
  rescue_from UseCases::SendContactEmailUseCase::ValidationError, with: :render_validation_error
  rescue_from ActionController::TooManyRequests, with: :render_too_many_requests
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

  def create
    UseCases::SendContactEmailUseCase.new.execute(**contact_params)

    render json: { message: t("contacts.success") }, status: :ok
  end

  private

  def contact_params
    params.permit(:name, :email, :message).to_h.symbolize_keys
  end

  def render_validation_error(e)
    render json: { message: t("contacts.validation_failed"), errors: e.errors }, status: :unprocessable_content
  end

  def render_too_many_requests
    render json: { message: t("contacts.too_many_requests") }, status: :too_many_requests
  end

  def render_invalid_authenticity_token
    render json: { message: t("contacts.invalid_authenticity_token") }, status: :unprocessable_content
  end

  def render_internal_error(e)
    Rails.logger.error(e)
    render json: { message: t("contacts.internal_error"), action: t("contacts.internal_error_action") }, status: :internal_server_error
  end
end

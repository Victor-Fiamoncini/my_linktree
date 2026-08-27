class ContactsController < ApplicationController
  rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

  rescue_from StandardError, with: :redirect_with_internal_error
  rescue_from ArgumentError, with: :redirect_with_missing_fields
  rescue_from ActionController::TooManyRequests, with: :redirect_with_too_many_requests
  rescue_from ActionController::InvalidAuthenticityToken, with: :redirect_with_invalid_authenticity_token

  def create
    UseCases::SendContactEmailUseCase.new.execute(**contact_params)

    flash[:notice] = "Thank you for your message! I'll get back to you as soon as possible."
    redirect_to root_path(anchor: "contact")
  end

  private

  def contact_params
    params.permit(:name, :email, :message).to_h.symbolize_keys
  end

  def redirect_with_missing_fields(e)
    flash[:alert] = "#{e.message}. Check if all required fields are provided and try again."
    redirect_to root_path(anchor: "contact")
  end

  def redirect_with_too_many_requests
    flash[:alert] = "Too many requests. Please wait a moment before trying again."
    redirect_to root_path(anchor: "contact")
  end

  def redirect_with_invalid_authenticity_token
    flash[:alert] = "Your session expired. Please try submitting the form again."
    redirect_to root_path(anchor: "contact")
  end

  def redirect_with_internal_error(e)
    Rails.logger.error(e)
    flash[:alert] = "Internal Server Error. Please contact the administrator of the application."
    redirect_to root_path(anchor: "contact")
  end
end

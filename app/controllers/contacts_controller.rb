class ContactsController < ApplicationController
  RATE_LIMITER = RateLimiter.new(key_prefix: "contact", max_requests: 2, window: 10.minutes)

  rescue_from StandardError, with: :redirect_with_internal_error
  rescue_from MissingRequiredFieldsError, with: :redirect_with_missing_fields

  def create
    unless RATE_LIMITER.allowed?(rate_limit_identifier)
      flash[:alert] = "Too many requests. Please wait a moment before trying again."
      return redirect_to root_path(anchor: "contact")
    end

    UseCases::SendContactEmailUseCase.new.execute(**contact_params)

    flash[:notice] = "Thank you for your message! I'll get back to you as soon as possible."
    redirect_to root_path(anchor: "contact")
  end

  private

  def contact_params
    params.permit(:name, :email, :message).to_h.symbolize_keys
  end

  def redirect_with_missing_fields(e)
    flash[:alert] = "#{e.message}. #{e.action}"
    redirect_to root_path(anchor: "contact")
  end

  def redirect_with_internal_error(e)
    Rails.logger.error(e)
    flash[:alert] = "Internal Server Error. Please contact the administrator of the application."
    redirect_to root_path(anchor: "contact")
  end
end

class ContactsController < ApplicationController
  RATE_LIMITER = RateLimiter.new(key_prefix: "contact", max_requests: 2, window: 10.minutes)

  def create
    ip = request.headers["X-Forwarded-For"] || request.headers["X-Real-IP"]

    unless RATE_LIMITER.allowed?(ip)
      error = TooManyRequestsError.new
      flash[:alert] = "#{error.message}. #{error.action}"
      return redirect_to root_path(anchor: "contact")
    end

    UseCases::SendContactEmailUseCase.new.execute(**contact_params)

    flash[:notice] = "Thank you for your message! I'll get back to you as soon as possible."
    redirect_to root_path(anchor: "contact")
  rescue MissingRequiredFieldsError => e
    flash[:alert] = "#{e.message}. #{e.action}"
    redirect_to root_path(anchor: "contact")
  rescue => e
    Rails.logger.error(e)
    error = InternalServerError.new(cause: e)
    flash[:alert] = "#{error.message}. #{error.action}"
    redirect_to root_path(anchor: "contact")
  end

  private

  def contact_params
    { name: params[:name], email: params[:email], message: params[:message] }
  end
end

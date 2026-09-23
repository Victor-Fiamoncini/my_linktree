class ContactsController < ApplicationController
  rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

  rescue_from StandardError, with: :render_internal_error
  rescue_from SendContactEmailUseCase::ValidationError, with: :render_validation_error
  rescue_from ActionController::TooManyRequests, with: :render_too_many_requests
  rescue_from ActionController::InvalidAuthenticityToken, with: :render_invalid_authenticity_token

  def create
    SendContactEmailUseCase.new.execute(**contact_params)

    Rails.event.notify(
      "contact.message.sent",
      locale: I18n.locale.to_s,
      message_length: contact_params[:message].to_s.length,
      **LogRedaction.contact(contact_params[:email])
    )

    render json: { message: t("contacts.success") }, status: :ok
  end

  private

  def contact_params
    params.permit(:name, :email, :message).to_h.symbolize_keys
  end

  def render_validation_error(e)
    Rails.event.notify("contact.message.rejected", severity: "warn", fields: e.errors.keys.map(&:to_s))

    render json: { message: t("contacts.validation_failed"), errors: e.errors }, status: :unprocessable_content
  end

  def render_too_many_requests
    Rails.event.notify("contact.rate_limited", severity: "warn")

    render json: { message: t("contacts.too_many_requests") }, status: :too_many_requests
  end

  def render_invalid_authenticity_token
    Rails.event.notify("contact.csrf_rejected", severity: "warn")

    render json: { message: t("contacts.invalid_authenticity_token") }, status: :unprocessable_content
  end

  # See Api::BaseController#render_internal_server_error on logging the class rather than the
  # exception object.
  def render_internal_error(e)
    Rails.logger.error("#{e.class}: #{e.message}")

    Rails.event.notify(
      "contact.error",
      severity: "error",
      error_class: e.class.name,
      error_message: e.message,
      backtrace: e.backtrace&.first(5)
    )

    render json: { message: t("contacts.internal_error"), action: t("contacts.internal_error_action") }, status: :internal_server_error
  end
end

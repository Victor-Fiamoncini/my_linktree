module Api
  class ContactsController < FormController
    rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

    rescue_from ValidationError, with: :render_validation_error

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

      render json: { message: localized(:validation_failed), errors: e.errors }, status: :unprocessable_content
    end

    def event_namespace
      "contact"
    end

    def internal_server_error_body
      super.merge(action: localized(:internal_error_action))
    end
  end
end

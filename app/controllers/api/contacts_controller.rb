module Api
  class ContactsController < FormController
    rate_limit to: 2, within: 10.minutes, by: -> { rate_limit_identifier }, only: :create

    rescue_from ValidationError do |e|
      render_error :unprocessable_content, "contact.message.rejected", { message: localized(:validation_failed), errors: e.errors },
        fields: e.errors.keys.map(&:to_s)
    end

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

    def event_namespace
      "contact"
    end

    def internal_server_error_body
      super.merge(action: localized(:internal_error_action))
    end
  end
end

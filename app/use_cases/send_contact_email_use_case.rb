class SendContactEmailUseCase
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  def execute(name:, email:, message:)
    errors = {}
    errors[:name] = I18n.t("contacts.errors.blank") if name.blank?

    if email.blank?
      errors[:email] = I18n.t("contacts.errors.blank")
    elsif !email.match?(EMAIL_FORMAT)
      errors[:email] = I18n.t("contacts.errors.invalid_email")
    end

    errors[:message] = I18n.t("contacts.errors.blank") if message.blank?

    raise ValidationError, errors if errors.any?

    ContactMailer.new_contact(name: name, email: email, message: message).deliver_later
    nil
  end
end

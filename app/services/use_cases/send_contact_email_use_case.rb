module UseCases
  class SendContactEmailUseCase
    def execute(name:, email:, message:)
      raise MissingRequiredFieldsError if name.blank? || email.blank? || message.blank?

      ContactMailer.new_contact(name: name, email: email, message: message).deliver_now
      nil
    end
  end
end

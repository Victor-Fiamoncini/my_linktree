module UseCases
  class SendContactEmailUseCase
    class ValidationError < ArgumentError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.values.join(", "))
      end
    end

    EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

    def execute(name:, email:, message:)
      errors = {}
      errors[:name] = "can't be blank" if name.blank?

      if email.blank?
        errors[:email] = "can't be blank"
      elsif !email.match?(EMAIL_FORMAT)
        errors[:email] = "is invalid"
      end

      errors[:message] = "can't be blank" if message.blank?

      raise ValidationError, errors if errors.any?

      ContactMailer.new_contact(name: name, email: email, message: message).deliver_later
      nil
    end
  end
end

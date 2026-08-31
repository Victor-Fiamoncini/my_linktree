module UseCases
  class SendHireRequestUseCase
    class ValidationError < ArgumentError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.values.join(", "))
      end
    end

    def execute(name:, contact:, brief:, agent: nil)
      errors = {}
      errors[:name] = "can't be blank" if name.blank?
      errors[:contact] = "can't be blank" if contact.blank?
      errors[:brief] = "can't be blank" if brief.blank?

      raise ValidationError, errors if errors.any?

      ContactMailer.agent_hire_request(name: name, contact: contact, brief: brief, agent: agent).deliver_later
      nil
    end
  end
end

class SendHireRequestUseCase
  def execute(name: nil, contact: nil, brief: nil, agent: nil)
    errors = {}
    errors[:name] = "can't be blank" if name.blank?
    errors[:contact] = "can't be blank" if contact.blank?
    errors[:brief] = "can't be blank" if brief.blank?

    raise ValidationError, errors if errors.any?

    ContactMailer.agent_hire_request(name: name, contact: contact, brief: brief, agent: agent).deliver_later
    nil
  end
end

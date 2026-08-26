class ApplicationError < StandardError
  attr_reader :action

  def initialize(message, action:)
    super(message)
    @action = action
  end

  def as_json(*)
    { name: self.class.name, message: message, action: action }
  end
end

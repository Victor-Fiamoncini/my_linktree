class ValidationError < ArgumentError
  attr_reader :errors

  def initialize(errors)
    @errors = errors
    super(errors.values.join(", "))
  end
end

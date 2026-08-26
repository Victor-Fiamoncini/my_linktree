class MissingRequiredFieldsError < ApplicationError
  def initialize
    super("Missing required fields", action: "Check if all required fields are provided and try again.")
  end
end

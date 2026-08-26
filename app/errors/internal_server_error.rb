class InternalServerError < ApplicationError
  attr_reader :original_error

  def initialize(cause: nil)
    super("Internal Server Error", action: "Please contact the administrator of the application.")
    @original_error = cause
  end
end

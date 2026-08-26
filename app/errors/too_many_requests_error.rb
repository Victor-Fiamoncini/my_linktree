class TooManyRequestsError < ApplicationError
  def initialize
    super("Too many requests", action: "Please wait a moment before trying again.")
  end
end

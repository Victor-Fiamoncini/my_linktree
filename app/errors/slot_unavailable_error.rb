class SlotUnavailableError < ApplicationError
  def initialize
    super("Slot unavailable", action: "Please choose a different slot and try again.")
  end
end

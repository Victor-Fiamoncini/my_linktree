class Booking < ApplicationRecord
  validates :name, :email, :slot_start, presence: true
  validates :slot_start, uniqueness: true

  scope :upcoming, ->(from:, to:) { where(slot_start: from..to) }
end

class Booking < ApplicationRecord
  validates :name, :email, :slot_start, presence: true
  validates :name, :email, :company, length: { maximum: 255 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :slot_start, uniqueness: true

  scope :upcoming, ->(from:, to:) { where(slot_start: from..to) }
end

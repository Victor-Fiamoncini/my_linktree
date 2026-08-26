class AgentConnection < ApplicationRecord
  validates :tool, presence: true

  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }
end

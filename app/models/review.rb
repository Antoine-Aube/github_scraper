class Review < ApplicationRecord
  belongs_to :pull_request
  belongs_to :user
  
  validates :state, presence: true, inclusion: { in: %w[APPROVED CHANGES_REQUESTED COMMENTED DISMISSED PENDING] }
  validates :submitted_at, presence: true
end

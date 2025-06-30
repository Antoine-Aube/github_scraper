class Repository < ApplicationRecord
  has_many :pull_requests, dependent: :destroy
  
  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
  validates :private, inclusion: { in: [true, false] }
  validates :archived, inclusion: { in: [true, false] }
end

class Repository < ApplicationRecord
  has_many :pull_requests, dependent: :destroy
  
  validates :url, presence: true, uniqueness: true
end

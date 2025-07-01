class User < ApplicationRecord
  has_many :pull_requests, foreign_key: 'author_id', dependent: :nullify
  has_many :reviews, foreign_key: 'user_id', dependent: :nullify
  
  validates :github_id, uniqueness: true, allow_nil: true
end

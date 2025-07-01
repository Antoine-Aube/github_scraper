class PullRequest < ApplicationRecord
  belongs_to :repository
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_many :reviews, dependent: :destroy
  
  validates :number, presence: true, uniqueness: { scope: :repository_id }
end

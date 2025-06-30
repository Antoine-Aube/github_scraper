class PullRequest < ApplicationRecord
  belongs_to :repository
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  has_many :reviews, dependent: :destroy
  
  validates :number, presence: true, uniqueness: { scope: :repository_id }
  validates :title, presence: true
  validates :additions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :deletions, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :changed_files, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :commits_count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end

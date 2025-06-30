class RemoveCommitIdFromReviews < ActiveRecord::Migration[8.0]
  def change
    remove_column :reviews, :commit_id
  end
end

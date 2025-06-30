class AddGithubIdToReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :reviews, :github_id, :bigint
    add_column :reviews, :body, :text
    add_column :reviews, :commit_id, :string
  end
end

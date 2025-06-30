class AddAuthorToPullRequests < ActiveRecord::Migration[8.0]
  def change
    add_reference :pull_requests, :author, null: false, foreign_key: { to_table: :users }
    remove_column :pull_requests, :author, :string
  end
end

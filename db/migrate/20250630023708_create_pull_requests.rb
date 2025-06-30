class CreatePullRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :pull_requests do |t|
      t.references :repository, null: false, foreign_key: true
      t.integer :number
      t.string :title
      t.datetime :closed_at
      t.datetime :merged_at
      t.string :author
      t.integer :additions
      t.integer :deletions
      t.integer :changed_files
      t.integer :commits_count

      t.timestamps
    end
  end
end

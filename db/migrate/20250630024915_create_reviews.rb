class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :pull_request, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :state
      t.datetime :submitted_at

      t.timestamps
    end
  end
end

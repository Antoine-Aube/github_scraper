class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :github_login
      t.integer :github_id
      t.string :name

      t.timestamps
    end
  end
end

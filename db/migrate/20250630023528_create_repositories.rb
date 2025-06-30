class CreateRepositories < ActiveRecord::Migration[8.0]
  def change
    create_table :repositories do |t|
      t.string :name
      t.string :url
      t.boolean :private
      t.boolean :archived

      t.timestamps
    end
  end
end

class CreateChapters < ActiveRecord::Migration[5.0]
  def change
    create_table :chapters do |t|
      t.string :name
      t.text :description
      t.integer :level

      t.timestamps
    end
  end
end

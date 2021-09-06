class CreateExercises < ActiveRecord::Migration[5.0]
  def change
    create_table :exercises do |t|
      t.text :statement
      t.boolean :decimal, default: false
      t.float :answer
      t.integer :chapter_id
      t.integer :position

      t.timestamps
    end
  end
end

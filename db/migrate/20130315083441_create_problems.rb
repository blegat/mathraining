class CreateProblems < ActiveRecord::Migration
  def change
    create_table :problems do |t|
      t.string :name
      t.text :statement
      t.integer :chapter_id
      t.integer :position

      t.timestamps
    end
  end
end

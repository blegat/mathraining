class CreateProblems < ActiveRecord::Migration[5.0]
  def change
    create_table :problems do |t|
      t.string :name
      t.text :statement
      t.references :chapter
      t.integer :position

      t.timestamps
    end
  end
end

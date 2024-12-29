class CreatePuzzles < ActiveRecord::Migration[7.1]
  def change
    create_table :puzzles do |t|
      t.text :statement
      t.string :code
      t.integer :position
      t.text :explanation
    end
    
    create_table :puzzleattempts do |t|
      t.references :user
      t.references :puzzle
      t.string :code
    end
  end
end

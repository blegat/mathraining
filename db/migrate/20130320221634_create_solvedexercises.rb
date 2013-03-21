class CreateSolvedexercises < ActiveRecord::Migration
  def change
    create_table :solvedexercises do |t|
      t.integer :user_id
      t.integer :exercise_id
      t.float :guess
      t.boolean :correct
      t.integer :nb_guess

      t.timestamps
    end
    
    add_index :solvedexercises, :user_id
  end
end

class CreateSolvedexercises < ActiveRecord::Migration[5.0]
  def change
    create_table :solvedexercises do |t|
      t.references :user
      t.references :exercise
      t.float :guess
      t.boolean :correct
      t.integer :nb_guess

      t.timestamps
    end
  end
end

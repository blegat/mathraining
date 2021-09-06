class WhoSolvedExercises < ActiveRecord::Migration[5.0]
  def change
    add_index :solvedexercises, :exercise_id
    add_index :solvedqcms, :qcm_id
  end
end

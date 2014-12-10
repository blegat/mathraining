class WhoSolvedExercises < ActiveRecord::Migration
  def change
    add_index :solvedexercises, :exercise_id
    add_index :solvedqcms, :qcm_id
  end
end

class RemoveOldExercises < ActiveRecord::Migration[5.0]
  def change
    drop_table :qcms
    drop_table :exercises
    drop_table :solvedqcms
    drop_table :solvedexercises
    drop_table :choices
    drop_table :choices_solvedqcms
    remove_column :subjects, :qcm_id
    remove_column :subjects, :exercise_id
  end
end

class AddIndexForSolvedExercises < ActiveRecord::Migration[5.0]
  def change
    add_index :solvedexercises, :resolutiontime, order: "DESC"
    add_index :solvedqcms, :resolutiontime, order: "DESC"
  end
end

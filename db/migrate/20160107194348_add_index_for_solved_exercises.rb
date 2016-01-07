class AddIndexForSolvedExercises < ActiveRecord::Migration
  def change
    add_index :solvedexercises, :resolutiontime, order: "DESC"
    add_index :solvedqcms, :resolutiontime, order: "DESC"
  end
end

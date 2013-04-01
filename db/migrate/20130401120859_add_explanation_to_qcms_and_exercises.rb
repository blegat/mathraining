class AddExplanationToQcmsAndExercises < ActiveRecord::Migration
  def change
    add_column :qcms, :explanation, :text
    add_column :exercises, :explanation, :text
  end
end

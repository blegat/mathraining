class AddExplanationToQcmsAndExercises < ActiveRecord::Migration[5.0]
  def change
    add_column :qcms, :explanation, :text
    add_column :exercises, :explanation, :text
  end
end

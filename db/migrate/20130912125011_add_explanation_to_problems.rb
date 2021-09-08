class AddExplanationToProblems < ActiveRecord::Migration[5.0]
  def change
  	add_column :problems, :explanation, :text, :default => ""
  end
end

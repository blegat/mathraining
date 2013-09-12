class AddExplanationToProblems < ActiveRecord::Migration
  def change
  	add_column :problems, :explanation, :text, :default => ""
  end
end

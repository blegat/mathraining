class AddMarkschemeToProblems < ActiveRecord::Migration[5.0]
  def change
    add_column :problems, :markscheme, :text, :default => ""
  end
end

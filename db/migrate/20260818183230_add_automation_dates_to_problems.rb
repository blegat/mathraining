class AddAutomationDatesToProblems < ActiveRecord::Migration[8.1]
  def change
    add_column :problems, :publication_date, :date # To automatically publish a problem
    add_column :problems, :archiving_date, :date # To automatically archive a problem
  end
end

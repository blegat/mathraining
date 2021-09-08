class AddImportantToSubjects < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :important, :boolean, :default => false
  end
end

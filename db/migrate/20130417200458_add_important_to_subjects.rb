class AddImportantToSubjects < ActiveRecord::Migration
  def change
    add_column :subjects, :important, :boolean, :default => false
  end
end

class AddFondationColumn < ActiveRecord::Migration
  def change
    add_column :sections, :fondation, :boolean, :default => false
  end
end

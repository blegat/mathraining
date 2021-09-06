class AddFondationColumn < ActiveRecord::Migration[5.0]
  def change
    add_column :sections, :fondation, :boolean, :default => false
  end
end

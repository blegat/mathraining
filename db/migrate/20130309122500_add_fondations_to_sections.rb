class AddFondationsToSections < ActiveRecord::Migration
  def change
    add_column :sections, :fondations, :bool
  end
end

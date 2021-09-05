class AddMedalsToContests < ActiveRecord::Migration[5.0]
  def change
    add_column :contests, :medal, :boolean, :default => false
    add_column :contestscores, :medal, :integer
  end
end

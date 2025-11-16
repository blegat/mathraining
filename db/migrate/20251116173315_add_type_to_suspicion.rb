class AddTypeToSuspicion < ActiveRecord::Migration[7.1]
  def change
    add_column :suspicions, :cheating_type, :integer, :default => 0
  end
end

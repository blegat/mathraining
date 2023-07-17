class AddCorrectionLevelToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :correction_level, :integer, :default => 0
  end
end

class AddCorrectors < ActiveRecord::Migration[5.0]
  def change
  	add_column :users, :corrector, :boolean, :default => false
  end
end

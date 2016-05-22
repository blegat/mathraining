class AddCorrectors < ActiveRecord::Migration
  def change
  	add_column :users, :corrector, :boolean, :default => false
  end
end

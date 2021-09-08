class AddMaxScoreToSections < ActiveRecord::Migration[5.0]
  def change
  
  	add_column :sections, :max_score, :integer, :default => 0
  end
end

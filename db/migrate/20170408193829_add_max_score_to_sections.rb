class AddMaxScoreToSections < ActiveRecord::Migration
  def change
  
  	add_column :sections, :max_score, :integer, :default => 0
  end
end

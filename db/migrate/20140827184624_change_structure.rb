class ChangeStructure < ActiveRecord::Migration
  def change
    add_column :problems, :section_id, :integer, :default => 1
    add_index :problems, :section_id
    
    add_column :problems, :number, :integer, :default => 1
    
    create_table :chapters_problems, :id => false do |t|
      t.references :chapter
      t.references :problem
    end
  end
end

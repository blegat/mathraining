class ChangeStructure < ActiveRecord::Migration[5.0]
  def change
    add_reference :problems, :section
    
    add_column :problems, :number, :integer, :default => 1
    
    create_table :chapters_problems, :id => false do |t|
      t.references :chapter
      t.references :problem
    end
  end
end

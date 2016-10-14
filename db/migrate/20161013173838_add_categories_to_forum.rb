class AddCategoriesToForum < ActiveRecord::Migration
  def change
    create_table :categories do |c|
      c.string :name
    end
    
    add_column :subjects, :exercise_id, :integer
    add_column :subjects, :qcm_id, :integer
    add_column :subjects, :category_id, :integer
  end
end

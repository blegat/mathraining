class PrepareToRatings < ActiveRecord::Migration
  def change
    add_column :users, :rating, :integer
    add_column :problems, :level, :integer
    create_table :pointspersection do |t|
      t.integer :user_id
      t.integer :section_id
      t.integer :points
      t.integer :max_points
    end
    add_index :pointspersection, :user_id
  end
end

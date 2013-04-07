class PrepareToRatings < ActiveRecord::Migration
  def change
    add_column :problems, :level, :integer
    create_table :pointspersections do |t|
      t.integer :user_id
      t.integer :section_id
      t.integer :points
    end
    add_index :pointspersections, :user_id
  end
end

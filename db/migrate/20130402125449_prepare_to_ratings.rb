class PrepareToRatings < ActiveRecord::Migration[5.0]
  def change
    add_column :problems, :level, :integer
    create_table :pointspersections do |t|
      t.references :user
      t.references :section
      t.integer :points
    end
  end
end

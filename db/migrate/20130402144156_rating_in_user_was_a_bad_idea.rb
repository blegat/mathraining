class RatingInUserWasABadIdea < ActiveRecord::Migration
  def change
    remove_column :users, :rating
    remove_column :pointspersection, :max_points
    create_table :points do |t|
      t.integer :user_id
      t.integer :rating
    end
    add_index :points, :user_id
  end
end

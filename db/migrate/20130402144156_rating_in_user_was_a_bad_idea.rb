class RatingInUserWasABadIdea < ActiveRecord::Migration
  def change
    create_table :points do |t|
      t.integer :user_id
      t.integer :rating
    end
    add_index :points, :user_id
  end
end

class RatingInUserWasABadIdea < ActiveRecord::Migration[5.0]
  def change
    create_table :points do |t|
      t.references :user
      t.integer :rating
    end
  end
end

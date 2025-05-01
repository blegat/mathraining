class CreateFavoriteproblems < ActiveRecord::Migration[7.1]
  def change
    create_table :favoriteproblems do |t|
      t.references :user
      t.references :problem
    end
  end
end

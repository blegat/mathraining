class ImproveIndexForUsers < ActiveRecord::Migration[7.1]
  def change
    remove_index :users, [:admin, :active, :rating,], order: {rating: :desc}
    remove_index :users, [:admin, :active, :country_id, :rating], order: {rating: :desc}
    
    add_index :users, [:admin, :active, :rating, :id], order: {rating: :desc}
    add_index :users, [:admin, :active, :country_id, :rating, :id], order: {rating: :desc}
  end
end

class AddSomeMoreIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :users, [:admin, :active, :rating], order: {rating: :desc}
    add_index :users, [:admin, :active, :country_id, :rating], order: {rating: :desc}
  end
end

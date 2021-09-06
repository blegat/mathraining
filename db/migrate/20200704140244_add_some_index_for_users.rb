class AddSomeIndexForUsers < ActiveRecord::Migration[5.0]
  def change
    add_index :users, [:rating], order: "DESC"
  end
end

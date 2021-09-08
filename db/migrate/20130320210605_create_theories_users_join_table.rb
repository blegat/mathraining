class CreateTheoriesUsersJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :theories_users, :id => false do |t|
      t.references :theory
      t.references :user
    end
  end
end

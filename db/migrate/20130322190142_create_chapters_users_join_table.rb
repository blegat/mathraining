class CreateChaptersUsersJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_table :chapters_users, :id => false do |t|
      t.references :chapter
      t.references :user
    end
  end
end

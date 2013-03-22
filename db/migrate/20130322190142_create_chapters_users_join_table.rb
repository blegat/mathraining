class CreateChaptersUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :chapters_users, :id => false do |t|
      t.references :chapter
      t.references :user
    end
  end
end

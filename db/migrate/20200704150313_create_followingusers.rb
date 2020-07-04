class CreateFollowingusers < ActiveRecord::Migration[5.0]
  def change
    create_table :followingusers do |t|
      t.references :user
      t.references :followed_user
    end
  end
end

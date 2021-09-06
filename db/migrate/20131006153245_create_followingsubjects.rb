class CreateFollowingsubjects < ActiveRecord::Migration[5.0]
  def change
    create_table :followingsubjects do |t|
      t.references :user
      t.references :subject
    end
  end
end

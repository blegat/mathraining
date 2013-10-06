class CreateFollowingsubjects < ActiveRecord::Migration
  def change
    create_table :followingsubjects do |t|
      t.references :user
      t.references :subject
    end
    
    add_index :followingsubjects, :user_id
    add_index :followingsubjects, :subject_id
  end
end

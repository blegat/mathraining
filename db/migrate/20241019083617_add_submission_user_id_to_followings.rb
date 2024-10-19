class AddSubmissionUserIdToFollowings < ActiveRecord::Migration[7.1]
  def change
    add_column :followings, :submission_user_id, :integer
    add_index :followings, :submission_user_id
    
    up_only do
      execute("UPDATE followings f SET submission_user_id = s.user_id FROM submissions s WHERE s.id = f.submission_id")
    end
  end
end

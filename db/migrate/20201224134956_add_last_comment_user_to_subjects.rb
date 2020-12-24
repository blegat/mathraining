class AddLastCommentUserToSubjects < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :lastcomment_user_id, :integer
    add_index :subjects, :lastcomment
  end
end

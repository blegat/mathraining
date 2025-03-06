class AddUserToSavedreplies < ActiveRecord::Migration[7.1]
  def change
    add_reference :savedreplies, :user
    
    up_only do
      Savedreply.update_all(user_id: 0)
    end
  end
end

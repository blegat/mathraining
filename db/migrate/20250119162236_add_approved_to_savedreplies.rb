class AddApprovedToSavedreplies < ActiveRecord::Migration[7.1]
  def change
    add_column :savedreplies, :approved, :boolean
    add_index :savedreplies, :approved
    
    up_only do
      Savedreply.update_all(approved: true)
    end
  end
end

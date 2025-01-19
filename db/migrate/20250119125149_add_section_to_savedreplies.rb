class AddSectionToSavedreplies < ActiveRecord::Migration[7.1]
  def change
    add_reference :savedreplies, :section
    
    up_only do
      Savedreply.update_all(section_id: 0)
    end
  end
end

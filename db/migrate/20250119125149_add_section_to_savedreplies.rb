class AddSectionToSavedreplies < ActiveRecord::Migration[7.1]
  def change
    add_reference :savedreplies, :section
  end
end

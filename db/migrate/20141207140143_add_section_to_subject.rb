class AddSectionToSubject < ActiveRecord::Migration[5.0]
  def change
    add_column :subjects, :section_id, :integer
  end
end

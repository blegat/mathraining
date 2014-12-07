class AddSectionToSubject < ActiveRecord::Migration
  def change
    add_column :subjects, :section_id, :integer
  end
end

class RemovePaperClipFieldsFromMyfile < ActiveRecord::Migration[5.2]
  def change
    remove_column :myfiles, :file_file_name, :string
    remove_column :myfiles, :file_content_type, :string
    remove_column :myfiles, :file_file_size, :integer
    remove_column :myfiles, :file_updated_at, :datetime
  end
end

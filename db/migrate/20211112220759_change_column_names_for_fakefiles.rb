class ChangeColumnNamesForFakefiles < ActiveRecord::Migration[5.2]
  def change
    rename_column :fakefiles, :file_file_name, :filename
    rename_column :fakefiles, :file_content_type, :content_type
    rename_column :fakefiles, :file_file_size, :byte_size
    rename_column :fakefiles, :file_updated_at, :created_at
  end
end

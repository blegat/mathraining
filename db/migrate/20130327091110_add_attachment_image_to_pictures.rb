class AddAttachmentImageToPictures < ActiveRecord::Migration[5.0]
  def change
    add_column :pictures, :image_file_name, :string
    add_column :pictures, :image_content_type, :string
    add_column :pictures, :image_file_size, :integer
    add_column :pictures, :image_updated_at, :datetime
  end
end

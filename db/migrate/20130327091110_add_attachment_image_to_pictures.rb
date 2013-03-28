class AddAttachmentImageToPictures < ActiveRecord::Migration
  def self.up
    change_table :pictures do |t|
      t.attachment :image
    end
  end

  def self.down
    drop_attached_file :pictures, :image
  end
end

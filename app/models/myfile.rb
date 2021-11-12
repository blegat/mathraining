#encoding: utf-8

# == Schema Information
#
# Table name: myfiles
#
#  id                :integer          not null, primary key
#  myfiletable_type  :string
#  myfiletable_id    :integer
#  file_file_name    :string
#  file_content_type :string
#  file_file_size    :integer
#  file_updated_at   :datetime
#
class Myfile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_one_attached :file
  belongs_to :myfiletable, polymorphic: true, optional: true # Optional: true is needed because when we create the file we don't have yet the object

  # VALIDATIONS

  validates :file, attached: true,
                   content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'application/pdf', 'application/zip', 'application/msword', 'text/plain'], 
                   size: { less_than: 1.megabytes }

  # Indique si la pièce jointe est une image (pour voir si on l'affiche ou non)
  def is_image
    return (self.file.blob.content_type == 'image/jpeg' || self.file.blob.content_type == 'image/jpg' || self.file.blob.content_type == 'image/png' || self.file.blob.content_type == 'image/gif' || self.file.blob.content_type == 'image/bmp')
  end
  
  def fake_del
    ff = Fakefile.new
    ff.fakefiletable_type = self.myfiletable_type
    ff.fakefiletable_id = self.myfiletable_id
    ff.file_file_name = self.file.filename.base
    ff.file_content_type = self.file.blob.content_type
    ff.file_file_size = self.file.blob.byte_size
    ff.file_updated_at = self.file.blob.created_at
    ff.save
    self.file.blob.purge
    self.file.destroy
    self.destroy
    return ff
  end
  
  def self.fake_dels
    ajd = DateTime.now.to_date
    Myfile.where(:myfiletable_type => "Tchatmessage").each do |f|
      if f.file.blob.created_at.to_date + 28 < ajd
        f.fake_del
      end
    end
  end
end

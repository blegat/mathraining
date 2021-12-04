#encoding: utf-8

# == Schema Information
#
# Table name: myfiles
#
#  id               :integer          not null, primary key
#  myfiletable_type :string
#  myfiletable_id   :integer
#
class Myfile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_one_attached :file
  belongs_to :myfiletable, polymorphic: true, optional: true # Optional: true is needed because when we create the file we don't have yet the object

  # VALIDATIONS

  validates :file, attached: true,
                   content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'application/pdf', 'application/zip', 'application/msword', 'text/plain'], 
                   size: { less_than: 1.megabytes }
                   
  # OTHER METHODS

  # Tell if the file is an image
  def is_image
    return (self.file.blob.content_type == 'image/jpeg' || self.file.blob.content_type == 'image/jpg' || self.file.blob.content_type == 'image/png' || self.file.blob.content_type == 'image/gif' || self.file.blob.content_type == 'image/bmp')
  end
  
  # Delete the content of the file: replace it with a Fakefile
  def fake_del
    ff = Fakefile.create(:fakefiletable_type => self.myfiletable_type,
                         :fakefiletable_id   => self.myfiletable_id,
                         :filename           => self.file.filename.to_s,
                         :content_type       => self.file.blob.content_type,
                         :byte_size          => self.file.blob.byte_size,
                         :created_at         => self.file.blob.created_at)
    self.destroy # Should automatically purge the file
    return ff
  end
  
  # Delete the content of old files in tchatmessages (done every day at 2 am (see schedule.rb))
  def self.fake_dels
    today = DateTime.now.to_date
    Myfile.where(:myfiletable_type => "Tchatmessage").each do |f|
      if f.file.blob.created_at.to_date + 28 < today
        f.fake_del
      end
    end
  end
end

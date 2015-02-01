#encoding: utf-8
# == Schema Information
#
# Table name: submissionfiles
#
#  id                :integer          not null, primary key
#  submission_id        :integer
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime         not null
#

class Submissionfile < ActiveRecord::Base
  attr_accessible :file, :submission_id
  has_attached_file :file,
    :path => ':rails_root/public/system/:attachment/:class/:id/:basename_:hash.:extension',
    :url => '/system/:attachment/:class/:id/:basename_:hash.:extension',
    :hash_secret => "longSecretString"
  belongs_to :submission
  validates_attachment_presence :file
  validates_attachment_size :file, :less_than => 10.megabytes
  validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp', 'application/pdf', 'application/zip', 'application/msword', 'text/plain']
  
  def is_image
   if self.file.content_type == 'image/jpeg' || self.file.content_type == 'image/jpg' || self.file.content_type == 'image/png' || self.file.content_type == 'image/gif' || self.file.content_type == 'image/bmp'
     return true
   else
     return false
   end
  end
end

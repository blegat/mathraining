class Submissionfile < ActiveRecord::Base
  attr_accessible :file, :submission_id
  has_attached_file :file,
    :path => ':rails_root/non-public/system/:attachment/:class/:id/:basename.:extension',
    :url => '/:class/:id/:attachment' 
  belongs_to :submission
  validates_attachment_presence :file
  validates_attachment_size :file, :less_than => 5.megabytes
  validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp']
end

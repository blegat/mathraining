class Picture < ActiveRecord::Base
  attr_accessible :image, :user_id
  has_attached_file :image,
    :path => "public/system/:class/:id/:filename",
    :url => "/system/:class/:id/:basename.:extension"
  belongs_to :user
  validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 1.megabytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp']
end

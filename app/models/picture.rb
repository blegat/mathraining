#encoding: utf-8

# == Schema Information
#
# Table name: pictures
#
#  id                 :integer          not null, primary key
#  user_id            :integer
#  image_file_name    :string
#  image_content_type :string
#  image_file_size    :integer
#  image_updated_at   :datetime
#
class Picture < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_attached_file :image,
  :path => "public/system/:class/:id/:basename_:hash.:extension",
  :url => "/system/:class/:id/:basename_:hash.:extension",
  :hash_secret => "longSecretString"
  belongs_to :user

  # VALIDATIONS

  validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 1.megabytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp']

end

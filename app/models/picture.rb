#encoding: utf-8

# == Schema Information
#
# Table name: pictures
#
#  id         :integer          not null, primary key
#  access_key :string
#  user_id    :integer
#
# Indexes
#
#  index_pictures_on_user_id  (user_id)
#
class Picture < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_one_attached :image
  belongs_to :user
  
  # BEFORE, AFTER
  
  before_create :create_access_key

  # VALIDATIONS

  validates :image, attached: true,
                    content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp'], 
                    size: { less_than: 1.megabytes }
  
  # OTHER METHODS
  
  # Create a random access key
  def create_access_key
    self.access_key = SecureRandom.urlsafe_base64
  end

end

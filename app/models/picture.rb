#encoding: utf-8

# == Schema Information
#
# Table name: pictures
#
#  id      :integer          not null, primary key
#  user_id :integer
#
class Picture < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_one_attached :image
  belongs_to :user

  # VALIDATIONS

  validates :image, attached: true,
                    content_type: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/bmp'], 
                    size: { less_than: 1.megabytes }

end

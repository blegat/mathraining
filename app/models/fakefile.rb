#encoding: utf-8

# == Schema Information
#
# Table name: fakefiles
#
#  id                 :integer          not null, primary key
#  fakefiletable_type :string
#  fakefiletable_id   :integer
#  filename           :string
#  content_type       :string
#  byte_size          :integer
#  created_at         :datetime
#
class Fakefile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :fakefiletable, polymorphic: true
  
  # VALIDATIONS
  
  validates :filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, presence: true

end

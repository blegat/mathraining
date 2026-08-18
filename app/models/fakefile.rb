#encoding: utf-8

# == Schema Information
#
# Table name: fakefiles
#
#  id                 :integer          not null, primary key
#  byte_size          :integer
#  content_type       :string
#  fakefiletable_type :string
#  filename           :string
#  created_at         :datetime
#  fakefiletable_id   :integer
#
# Indexes
#
#  index_fakefiles_on_byte_size                                (byte_size)
#  index_fakefiles_on_fakefiletable_type_and_fakefiletable_id  (fakefiletable_type,fakefiletable_id)
#
class Fakefile < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :fakefiletable, polymorphic: true
  
  # VALIDATIONS
  
  validates :filename, presence: true
  validates :content_type, presence: true
  validates :byte_size, presence: true

end

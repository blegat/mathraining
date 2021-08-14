#encoding: utf-8

# == Schema Information
#
# Table name: actualities
#
#  id         :integer          not null, primary key
#  title      :string
#  content    :text
#  created_at :datetime
#  updated_at :datetime
#
class Actuality < ActiveRecord::Base

  # VALIDATIONS

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice

end

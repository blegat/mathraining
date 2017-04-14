#encoding: utf-8
# == Schema Information
#
# Table name: actualities
#
#  id          :integer          not null, primary key
#  title       :string(255)
#  content     :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Actuality < ActiveRecord::Base
  # attr_accessible :content, :title

  # VALIDATIONS

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
end

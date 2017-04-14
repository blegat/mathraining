#encoding: utf-8
# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string(255)
#  color        :string(255)
#  font_color   :string(255)
#  femininename :string(255)
#

class Color < ActiveRecord::Base
  # attr_accessible :pt, :name, :color, :font_color, :femininename

  # VALIDATIONS

  validates :pt, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :femininename, presence: true, length: { maximum: 255 }
  validates :color, presence: true, length: { is: 7 }
  validates :font_color, presence: true, length: { is: 7 }
end

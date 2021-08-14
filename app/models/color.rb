#encoding: utf-8

# == Schema Information
#
# Table name: colors
#
#  id           :integer          not null, primary key
#  pt           :integer
#  name         :string
#  color        :string
#  femininename :string
#
class Color < ActiveRecord::Base

  # VALIDATIONS

  validates :pt, presence: true
  validates :name, presence: true, length: { maximum: 255 }
  validates :femininename, presence: true, length: { maximum: 255 }
  validates :color, presence: true, length: { is: 7 }

end

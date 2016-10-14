#encoding: utf-8
# == Schema Information
#
# Table name: category
#
#  id           :integer          not null, primary key
#  name         :string(255)
#

class Category < ActiveRecord::Base
  attr_accessible :name
  
  # VALIDATIONS
  
  validates :name, presence: true, length: { maximum: 255 }
end

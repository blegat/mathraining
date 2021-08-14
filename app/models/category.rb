#encoding: utf-8

# == Schema Information
#
# Table name: categories
#
#  id   :integer          not null, primary key
#  name :string
#
class Category < ActiveRecord::Base
  # attr_accessible :name

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }
end

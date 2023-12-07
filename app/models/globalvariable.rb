#encoding: utf-8

# == Schema Information
#
# Table name: globalvariables
#
#  id      :integer          not null, primary key
#  key     :string
#  value   :boolean
#  message :text
#
class Globalvariable < ActiveRecord::Base

  # VALIDATIONS

  validates :key, presence: true
  validates :value, inclusion: [true, false]
end

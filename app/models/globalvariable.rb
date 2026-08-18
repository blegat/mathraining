#encoding: utf-8

# == Schema Information
#
# Table name: globalvariables
#
#  id      :bigint           not null, primary key
#  key     :string
#  message :text
#  value   :boolean
#
# Indexes
#
#  index_globalvariables_on_key  (key) UNIQUE
#
class Globalvariable < ActiveRecord::Base

  # VALIDATIONS

  validates :key, presence: true, uniqueness: true
  validates :value, inclusion: [true, false]
end

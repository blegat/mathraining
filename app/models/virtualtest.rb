#encoding: utf-8
# == Schema Information
#
# Table name: virtualtests
#
#  id       :integer          not null, primary key
#  duration :integer
#  number   :integer
#  online   :boolean
#

class Virtualtest < ActiveRecord::Base
  attr_accessible :duration, :number, :online
  
  has_many :problems
  has_many :takentests
  
  validates :duration, presence: true, numericality: { greater_than: 0 }
end

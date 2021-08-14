#encoding: utf-8

# == Schema Information
#
# Table name: virtualtests
#
#  id       :integer          not null, primary key
#  duration :integer
#  number   :integer          default(1)
#  online   :boolean
#
class Virtualtest < ActiveRecord::Base
  # attr_accessible :duration, :number, :online

  # BELONGS_TO, HAS_MANY

  has_many :problems
  has_many :takentests

  # VALIDATIONS

  validates :duration, presence: true, numericality: { greater_than: 0 }
end

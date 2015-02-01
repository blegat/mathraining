#encoding: utf-8
# == Schema Information
#
# Table name: points
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  section_id :integer
#  points     :integer
#

class Pointspersection < ActiveRecord::Base
  attr_accessible :points, :section_id
  
  # BELONGS_TO, HAS_MANY
  
  belongs_to :user
  
  # VALIDATIONS
  
  validates :points, presence: true
  validates :section_id, presence: true
end

#encoding: utf-8

# == Schema Information
#
# Table name: pointspersections
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  section_id :integer
#  points     :integer
#
class Pointspersection < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :section

  # VALIDATIONS
  
  validates :points, presence: true
  validates :section_id, presence: true

end

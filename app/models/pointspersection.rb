#encoding: utf-8

# == Schema Information
#
# Table name: pointspersections
#
#  id         :integer          not null, primary key
#  points     :integer
#  section_id :integer
#  user_id    :integer
#
# Indexes
#
#  index_pointspersections_on_section_id              (section_id)
#  index_pointspersections_on_user_id                 (user_id)
#  index_pointspersections_on_user_id_and_section_id  (user_id,section_id) UNIQUE
#
class Pointspersection < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :section

  # VALIDATIONS
  
  validates :points, presence: true
  validates :section_id, uniqueness: { scope: :user_id }

end

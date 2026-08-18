#encoding: utf-8

# == Schema Information
#
# Table name: takentestchecks
#
#  id           :integer          not null, primary key
#  takentest_id :integer
#
# Indexes
#
#  index_takentestchecks_on_takentest_id  (takentest_id) UNIQUE
#
class Takentestcheck < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :takentest
  
  # VALIDATIONS
  
  validates :takentest_id, uniqueness: true

end

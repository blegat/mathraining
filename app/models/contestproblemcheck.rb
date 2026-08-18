#encoding: utf-8

# == Schema Information
#
# Table name: contestproblemchecks
#
#  id                :integer          not null, primary key
#  contestproblem_id :integer
#
# Indexes
#
#  index_contestproblemchecks_on_contestproblem_id  (contestproblem_id) UNIQUE
#
class Contestproblemcheck < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY
  
  belongs_to :contestproblem
  
  # VALIDATIONS
  
  validates :contestproblem_id, uniqueness: true

end

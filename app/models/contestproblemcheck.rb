#encoding: utf-8

# == Schema Information
#
# Table name: contestproblemchecks
#
#  id                :integer          not null, primary key
#  contestproblem_id :integer
#
class Contestproblemcheck < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY
  
  belongs_to :contestproblem

end

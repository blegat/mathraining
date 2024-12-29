#encoding: utf-8

# == Schema Information
#
# Table name: puzzleattempts
#
#  id        :bigint           not null, primary key
#  user_id   :bigint
#  puzzle_id :bigint
#  code      :string
#
include ApplicationHelper

class Puzzleattempt < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :puzzle
  belongs_to :user

  # VALIDATIONS

  validates :puzzle_id, uniqueness: { scope: :user_id }
  
  validates_with CodeValidator
end

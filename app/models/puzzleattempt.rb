#encoding: utf-8

# == Schema Information
#
# Table name: puzzleattempts
#
#  id        :bigint           not null, primary key
#  code      :string
#  puzzle_id :bigint
#  user_id   :bigint
#
# Indexes
#
#  index_puzzleattempts_on_puzzle_id              (puzzle_id)
#  index_puzzleattempts_on_user_id                (user_id)
#  index_puzzleattempts_on_user_id_and_puzzle_id  (user_id,puzzle_id) UNIQUE
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

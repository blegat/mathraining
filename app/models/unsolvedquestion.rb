#encoding: utf-8

# == Schema Information
#
# Table name: unsolvedquestions
#
#  id              :integer          not null, primary key
#  user_id         :integer
#  question_id     :integer
#  guess           :float
#  nb_guess        :integer
#  last_guess_time :datetime
#
include ApplicationHelper

class Unsolvedquestion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :question
  belongs_to :user
  has_and_belongs_to_many :items
  
  # BEFORE, AFTER
  
  before_destroy { items.clear }

  # VALIDATIONS

  validates :question_id, uniqueness: { scope: :user_id }
  validates :guess, presence: true
  validates :nb_guess, presence: true, numericality: { greater_than_or_equal_to: 1 }

end

#encoding: utf-8

# == Schema Information
#
# Table name: unsolvedquestions
#
#  id              :bigint           not null, primary key
#  guess           :float
#  last_guess_time :datetime
#  nb_guess        :integer
#  question_id     :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_unsolvedquestions_on_question_id              (question_id)
#  index_unsolvedquestions_on_user_id                  (user_id)
#  index_unsolvedquestions_on_user_id_and_question_id  (user_id,question_id) UNIQUE
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
  validates :last_guess_time, presence: true

end

#encoding: utf-8

# == Schema Information
#
# Table name: solvedquestions
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  question_id    :integer
#  guess          :float
#  correct        :boolean
#  nb_guess       :integer
#  resolutiontime :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Solvedquestion < ActiveRecord::Base
  # attr_accessible :correct, :guess, :nb_guess, :resolutiontime

  # BELONGS_TO, HAS_MANY

  belongs_to :question
  belongs_to :user
  has_and_belongs_to_many :items

  # VALIDATIONS

  validates :question_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :guess, presence: true
  validates :nb_guess, presence: true, numericality: { greater_than_or_equal_to: 1 }
end

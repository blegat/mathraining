#encoding: utf-8
# == Schema Information
#
# Table name: solvedexercises
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  exercise_id    :integer
#  guess          :float
#  correct        :boolean
#  nb_guess       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resolutiontime :datetime
#

class Solvedexercise < ActiveRecord::Base
  # attr_accessible :correct, :guess, :nb_guess, :resolutiontime

  # BELONGS_TO, HAS_MANY

  belongs_to :exercise
  belongs_to :user

  # VALIDATIONS

  validates :exercise_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :guess, presence: true
  validates :nb_guess, presence: true, numericality: { greater_than_or_equal_to: 1 }
end

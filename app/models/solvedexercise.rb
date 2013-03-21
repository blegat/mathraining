# == Schema Information
#
# Table name: solvedexercises
#
#  id          :integer          not null, primary key
#  user_id     :integer
#  exercise_id :integer
#  guess       :float
#  correct     :boolean
#  nb_guess    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Solvedexercise < ActiveRecord::Base
  attr_accessible :correct, :guess, :nb_guess
  
  belongs_to :exercise
  belongs_to :user

  validates :exercise_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :guess, presence: true
  validates :nb_guess, presence: true, numericality:
    { greater_than_or_equal_to: 1 }
  validates :correct, inclusion: { in: [true, false] }
  
end

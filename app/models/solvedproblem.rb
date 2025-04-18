#encoding: utf-8

# == Schema Information
#
# Table name: solvedproblems
#
#  id              :integer          not null, primary key
#  problem_id      :integer
#  user_id         :integer
#  correction_time :datetime
#  submission_id   :integer
#  resolution_time :datetime
#
class Solvedproblem < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  belongs_to :submission

  # VALIDATIONS

  validates :problem_id, uniqueness: { scope: :user_id }
  validates :correction_time, presence: true
  validates :resolution_time, presence: true

end

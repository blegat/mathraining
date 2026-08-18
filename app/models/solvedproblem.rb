#encoding: utf-8

# == Schema Information
#
# Table name: solvedproblems
#
#  id              :integer          not null, primary key
#  correction_time :datetime
#  resolution_time :datetime
#  problem_id      :integer
#  submission_id   :integer
#  user_id         :integer
#
# Indexes
#
#  index_solvedproblems_on_problem_id                   (problem_id)
#  index_solvedproblems_on_resolution_time              (resolution_time)
#  index_solvedproblems_on_submission_id                (submission_id)
#  index_solvedproblems_on_user_id                      (user_id)
#  index_solvedproblems_on_user_id_and_problem_id       (user_id,problem_id) UNIQUE
#  index_solvedproblems_on_user_id_and_resolution_time  (user_id,resolution_time)
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

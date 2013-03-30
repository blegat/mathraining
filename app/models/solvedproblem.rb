class Solvedproblem < ActiveRecord::Base
  belongs_to :user
  belongs_to :problem

  validates :user_id, presence: true
  validates :problem_id, presence: true,
    uniqueness: { scope: :user_id }
end

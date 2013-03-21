class ProblemSubmission < ActiveRecord::Base
  attr_accessible :content
  belongs_to :user
  belongs_to :problem

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 8000 }
end

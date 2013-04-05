class Following < ActiveRecord::Base
  attr_accessible :read

  belongs_to :submission
  belongs_to :user

  validates :submission_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :submission_id }
  validates :read, inclusion: { in: [false, true] }
end

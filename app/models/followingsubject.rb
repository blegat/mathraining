class Followingsubject < ActiveRecord::Base
  belongs_to :subject
  belongs_to :user

  validates :subject_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :subject_id }

end

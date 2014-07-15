class Correction < ActiveRecord::Base
  attr_accessible :content
  belongs_to :user
  belongs_to :submission
  has_many :correctionfiles, dependent: :destroy

  validates :user_id, presence: true
  validates :submission_id, presence: true
  validates :content, presence: true, length: { maximum: 8000 }
end

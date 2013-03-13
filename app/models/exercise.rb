class Exercise < ActiveRecord::Base
  attr_accessible :answer, :chapter_id, :decimal, :statement, :position
  belongs_to :chapter
  validates :statement, presence: true, length: {maximum: 8000 }
  validates :answer, presence: true
  validates :position, presence: true
end

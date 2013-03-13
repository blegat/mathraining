class Qcm < ActiveRecord::Base
  attr_accessible :chapter_id, :many_answers, :position, :statement
  belongs_to :chapter
  validates :statement, presence: true, length: {maximum: 8000 }
  validates :position, presence: true
end

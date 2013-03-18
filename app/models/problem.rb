class Problem < ActiveRecord::Base
  attr_accessible :name, :position, :statement, :online
  belongs_to :chapter
  validates :name, presence: true, length: { maximum: 255 }
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :position, presence: true,
    uniqueness: { scope: :chapter_id },
    numericality: { greater_than_or_equal_to: 0 } 
end

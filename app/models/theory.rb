class Theory < ActiveRecord::Base
  attr_accessible :chapter_id, :content, :order, :title
  belongs_to :chapter
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: {maximum: 8000 }
  validates :order, presence: true
end

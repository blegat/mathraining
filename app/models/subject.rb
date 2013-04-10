class Subject < ActiveRecord::Base
  attr_accessible :content, :title, :chapter_id
  has_many :messages
  belongs_to :user
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :chapter_id, presence: true
  validates :user_id, presence: true
end

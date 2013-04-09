class Actuality < ActiveRecord::Base
  attr_accessible :content, :title, :tostudents
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
  validates :tostudents, inclusion: { in: [false, true] }
end

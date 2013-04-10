class Actuality < ActiveRecord::Base
  attr_accessible :content, :title
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true
end

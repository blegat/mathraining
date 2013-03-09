class Chapter < ActiveRecord::Base
  attr_accessible :description, :level, :name
  has_and_belongs_to_many :sections
  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: {maximum: 8000 }
  validates :level, presence: true, :numericality => { :greater_than_or_equal_to => 0, :less_than_or_equal_to => 10 }
end

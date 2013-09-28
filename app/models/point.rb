class Point < ActiveRecord::Base
  attr_accessible :rating, :forumseen
  belongs_to :user
  validates :rating, presence: true
end

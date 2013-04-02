class Point < ActiveRecord::Base
  attr_accessible :rating
  belongs_to :user
  validates :rating, presence: true
end

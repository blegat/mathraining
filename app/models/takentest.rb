include ApplicationHelper

class Takentest < ActiveRecord::Base
  attr_accessible :takentime, :status
  
  belongs_to :user
  belongs_to :virtualtest
  
  validates :status, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2 }
end

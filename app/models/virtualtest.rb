include ApplicationHelper

class Virtualtest < ActiveRecord::Base
  attr_accessible :duration, :number, :online
  
  has_many :problems
  has_many :takentests
  
  validates :duration, presence: true, numericality: { greater_than: 0 }
end

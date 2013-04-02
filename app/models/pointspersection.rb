class Pointspersection < ActiveRecord::Base
  attr_accessible :points, :section_id
  belongs_to :user
  validates :points, presence: true
  validates :section_id, presence: true
end

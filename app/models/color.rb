class Color < ActiveRecord::Base
  attr_accessible :pt, :name, :color, :font_color, :femininename
  
  validates :pt, presence: true
  validates :name, presence: true
  validates :femininename, presence: true
  validates :color, presence: true, length: { is: 7 }
  validates :font_color, presence: true, length: { is: 7 }
end

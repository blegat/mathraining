class Color < ActiveRecord::Base
  attr_accessible :pt, :name, :plural_name, :color, :font_color
  
  validates :pt, presence: true
  validates :name, presence: true
  validates :plural_name, presence: true
  validates :color, presence: true, length: { is: 7 }
  validates :font_color, presence: true, length: { is: 7 }
end

#encoding: utf-8
# == Schema Information
#
# Table name: sections
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  image       :string(255)
#  fondation   :boolean
#

class Section < ActiveRecord::Base
  # attr_accessible :description, :name, :image, :fondation

  # BELONGS_TO, HAS_MANY

  has_many :chapters
  has_many :problems

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
  def self.color(x)
    colors = ["#FFFFBB", "#FFBBBB", "#FFDD77", "#A0FFA0", "#AAF5FF", "#D8D8FF", "#F5F5F5"]
    return colors[x-1];
  end
end

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
  validates :description, length: { maximum: 8000 }
end

#encoding: utf-8

# == Schema Information
#
# Table name: sections
#
#  id                 :integer          not null, primary key
#  name               :string
#  description        :text
#  fondation          :boolean          default(FALSE)
#  max_score          :integer          default(0)
#  abbreviation       :string
#  short_abbreviation :string
#  initials           :string
#
class Section < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :chapters
  has_many :problems
  has_many :pointspersections

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :abbreviation, presence: true, length: { maximum: 15 }, uniqueness: true
  validates :short_abbreviation, presence: true, length: { maximum: 8 }, uniqueness: true
  validates :initials, presence: true, length: { maximum: 2 } # uniqueness: true is not set because otherwise the tests would fail
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
end

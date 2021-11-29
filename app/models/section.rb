#encoding: utf-8

# == Schema Information
#
# Table name: sections
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  fondation   :boolean          default(FALSE)
#  max_score   :integer          default(0)
#
class Section < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :chapters
  has_many :problems
  has_many :pointspersections

  # VALIDATIONS

  validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
end

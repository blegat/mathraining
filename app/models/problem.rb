#encoding: utf-8
# == Schema Information
#
# Table name: problems
#
#  id             :integer          not null, primary key
#  statement      :text
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  online         :boolean          default(FALSE)
#  level          :integer
#  explanation    :text
#  section_id     :integer
#  number         :integer
#  virtualtest_id :integer
#  position       :integer   (Pour les tests virtuels!)
#

include ApplicationHelper

class Problem < ActiveRecord::Base
  # attr_accessible :statement, :online, :level, :explanation, :number, :position, :origin

  # BELONGS_TO, HAS_MANY

  has_and_belongs_to_many :chapters, -> {uniq}
  belongs_to :section
  belongs_to :virtualtest

  has_many :submissions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems

  # VALIDATIONS

  validates :number, presence: true
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }
  validates :origin, length: { maximum: 255 }
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }

  # Retourne la valeur du problème
  def value
    return 15*level
  end
end

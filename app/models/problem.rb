#encoding: utf-8

# == Schema Information
#
# Table name: problems
#
#  id             :integer          not null, primary key
#  statement      :text
#  created_at     :datetime
#  updated_at     :datetime
#  online         :boolean          default(FALSE)
#  level          :integer
#  explanation    :text             default("")
#  section_id     :integer          default(1)
#  number         :integer          default(1)
#  virtualtest_id :integer          default(0)
#  position       :integer          default(0)
#  origin         :string
#  markscheme     :text             default("")
#
include ApplicationHelper

class Problem < ActiveRecord::Base
  # attr_accessible :statement, :online, :level, :explanation, :number, :position, :origin

  # BELONGS_TO, HAS_MANY

  has_and_belongs_to_many :chapters, -> {distinct}
  belongs_to :section
  belongs_to :virtualtest

  has_many :submissions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems
  has_one :subject

  # VALIDATIONS

  validates :number, presence: true
  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :explanation, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :origin, length: { maximum: 255 }
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }

  # Retourne la valeur du problème
  def value
    return 15*level
  end
end

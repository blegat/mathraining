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
#  position       :integer
#

include ApplicationHelper

class Problem < ActiveRecord::Base
  attr_accessible :statement, :online, :level, :explanation, :number, :position

  has_and_belongs_to_many :chapters, -> {uniq}
  belongs_to :section
  
  belongs_to :virtualtest

  has_many :submissions, dependent: :destroy

  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems

  validates :number, presence: true
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }
  
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }

  def to_tex
    "\\subsection{#{name}}\n#{html_to_tex(statement)}"
  end
  
  def value
    return 15*level
  end
end

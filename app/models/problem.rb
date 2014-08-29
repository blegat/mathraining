# == Schema Information
#
# Table name: problems
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  statement  :text
#  chapter_id :integer
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  online     :boolean          default(FALSE)
#

include ApplicationHelper

class Problem < ActiveRecord::Base
  attr_accessible :statement, :online, :level, :explanation, :number

  has_and_belongs_to_many :chapters, :uniq => true
  belongs_to :section

  has_many :submissions, dependent: :destroy

  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems

  validates :number, presence: true
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }
  validates :level, presence: true,
    inclusion: { in: [1, 2, 3, 4, 5] }

  def to_tex
    "\\subsection{#{name}}\n#{html_to_tex(statement)}"
  end
  
  def value
    return 15*level
  end
end

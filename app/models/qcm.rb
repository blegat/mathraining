# == Schema Information
#
# Table name: qcms
#
#  id           :integer          not null, primary key
#  statement    :text
#  many_answers :boolean
#  chapter_id   :integer
#  position     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  online       :boolean          default(FALSE)
#

class Qcm < ActiveRecord::Base
  attr_accessible :many_answers, :position, :statement, :online, :explanation, :level
  belongs_to :chapter
  has_many :choices, dependent: :destroy
  has_many :solvedqcms, dependent: :destroy
  has_many :users, :through => :solvedqcms
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }

  validates :position, presence: true,
    uniqueness: { scope: :chapter_id },
    numericality: { greater_than_or_equal_to: 0 }
    
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 4 }
    
  def value
    return 3*level
  end
end

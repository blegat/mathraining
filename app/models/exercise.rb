# == Schema Information
#
# Table name: exercises
#
#  id         :integer          not null, primary key
#  statement  :text
#  decimal    :boolean          default(FALSE)
#  answer     :float
#  chapter_id :integer
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  online     :boolean          default(FALSE)
#

class Exercise < ActiveRecord::Base
  attr_accessible :answer, :decimal, :position, :statement, :online, :explanation
  belongs_to :chapter
  has_many :solvedexercises, dependent: :destroy
  has_many :users, through: :solvedexercises

  validates :statement, presence: true, length: { maximum: 8000 }
  validates :explanation, length: { maximum: 8000 }
  validates :answer, presence: true
  validates :decimal, inclusion: { in: [false, true] }
  validates :position, presence: true,
    uniqueness: { scope: :chapter_id },
    numericality: { greater_than_or_equal_to: 0 }
end

# == Schema Information
#
# Table name: items
#
#  id          :integer          not null, primary key
#  ans         :string
#  ok          :boolean          default(FALSE)
#  question_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  position    :integer
#
class Item < ActiveRecord::Base
  # attr_accessible :ans, :ok, :qcm_id

  # BELONGS_TO, HAS_MANY

  belongs_to :question
  has_and_belongs_to_many :solvedquestion

  # VALIDATIONS

  validates :question_id, presence: true
  validates :ans, presence: true, length: { maximum: 255 }
  validates :ok, inclusion: { in: [true, false] }
  validates :position, presence: true

end

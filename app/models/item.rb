# == Schema Information
#
# Table name: items
#
#  id          :integer          not null, primary key
#  ans         :string
#  ok          :boolean          default(FALSE)
#  question_id :integer
#  position    :integer
#
class Item < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :question
  has_and_belongs_to_many :unsolvedquestion

  # VALIDATIONS

  validates :ans, presence: true, length: { maximum: 255 }
  validates :ok, inclusion: [true, false]
  validates :position, presence: true

end

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
#

class Qcm < ActiveRecord::Base
  attr_accessible :many_answers, :position, :statement
  belongs_to :chapter
  validates :statement, presence: true, length: {maximum: 8000 }
  validates :position, presence: true,
    uniqueness: { scope: :chapter_id },
    numericality: { greater_than_or_equal_to: 0 }
end

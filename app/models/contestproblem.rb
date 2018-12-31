#encoding: utf-8
# == Schema Information
#
# Table name: contestproblems
#
#  id                 :integer          not null, primary key
#  contest_id         :reference
#  number             :integer
#  statement          :text
#  origin             :string
#  start_time         :datetime
#  end_time           :datetime
#  status             :integer
#

# status = 0 --> in construction (contest is not online)
# status = 1 --> contest is online but problem is not published yet
# status = 2 --> problem is published and students can send solutions
# status = 3 --> problem is finished and solutions are being corrected
# status = 4 --> problem is finished ans solutions have been corrected

include ApplicationHelper

class Contestproblem < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  has_many :contestsolutions, dependent: :destroy

  # VALIDATIONS

  validates :status, presence: true
  validates :statement, presence: true, length: { maximum: 8000 }
  validates :origin, length: { maximum: 255 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :number, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 99 }

end

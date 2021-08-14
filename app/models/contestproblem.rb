#encoding: utf-8

# == Schema Information
#
# Table name: contestproblems
#
#  id              :integer          not null, primary key
#  contest_id      :integer
#  number          :integer
#  statement       :text
#  origin          :string
#  start_time      :datetime
#  end_time        :datetime
#  status          :integer          default(0)
#  reminder_status :integer          default(0)
#
# status = 0 --> in construction (contest is not online)
# status = 1 --> contest is online but problem is not published yet
# status = 2 --> problem is published and students can send solutions
# status = 3 --> problem is finished and solutions are being corrected
# status = 4 --> problem is finished ans solutions have been corrected
# status = 5 --> same as status = 4 but organizers are temporarily allowed to modify corrections

# reminder_status = 0 --> no reminder sent for this problem yet
# reminder_status = 1 --> reminder sent one day before publication
# reminder_status = 2 --> reminder send at publication

include ApplicationHelper

class Contestproblem < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  has_many :contestsolutions, dependent: :destroy
  has_one :contestproblemcheck, dependent: :destroy

  # VALIDATIONS

  validates :status, presence: true
  validates :reminder_status, presence: true
  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :origin, length: { maximum: 255 }
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :number, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 99 }

end

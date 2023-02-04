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
#  status          :integer          default("in_construction")
#  reminder_status :integer          default("no_reminder_sent")
#
include ApplicationHelper

class Contestproblem < ActiveRecord::Base

  enum status: {:in_construction => 0, # in construction (contest is not online)
                :not_started_yet => 1, # contest is online but problem is not published yet
                :in_progress     => 2, # problem is published and students can send solutions
                :in_correction   => 3, # problem is finished and solutions are being corrected
                :corrected       => 4, # problem is finished ans solutions have been corrected
                :in_recorrection => 5} # same as :corrected but organizers are temporarily allowed to modify corrections

  enum reminder_status: {:no_reminder_sent    => 0, # no reminder sent for this problem yet
                         :early_reminder_sent => 1, # reminder sent one day before publication
                         :all_reminders_sent  => 2} # reminder sent at publication

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
  validates :number, presence: true, numericality: { greater_than: 0 }
  
  # BEFORE, AFTER
  
  after_create :create_official_solution
  
  # OTHER METHODS
  
  def at_least(status_key)
    return Contestproblem.statuses[status] >= Contestproblem.statuses[status_key]
  end
  
  def at_most(status_key)
    return Contestproblem.statuses[status] <= Contestproblem.statuses[status_key]
  end
  
  private
  
  # Create the official solution just after the creation
  def create_official_solution
    Contestsolution.create(:contestproblem => self, :user_id => 0, :content => "-", :official => true, :corrected => true)
  end
end

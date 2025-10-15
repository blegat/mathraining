#encoding: utf-8

# == Schema Information
#
# Table name: problems
#
#  id               :integer          not null, primary key
#  statement        :text
#  online           :boolean          default(FALSE)
#  level            :integer
#  explanation      :text             default("-")
#  section_id       :integer
#  number           :integer          default(1)
#  virtualtest_id   :integer          default(0)
#  position         :integer          default(0)
#  origin           :string
#  markscheme       :text             default("-")
#  nb_solves        :integer          default(0)
#  first_solve_time :datetime
#  last_solve_time  :datetime
#  reviewed         :boolean          default(FALSE)
#
include ApplicationHelper

class Problem < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_and_belongs_to_many :chapters, -> {distinct}
  belongs_to :section
  belongs_to :virtualtest, optional: true

  has_many :submissions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :users, through: :solvedproblems
  has_many :externalsolutions, dependent: :destroy
  has_many :savedreplies, dependent: :destroy
  has_one :subject

  # VALIDATIONS

  validates :number, presence: true, uniqueness: true
  validates :statement, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :explanation, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :markscheme, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :origin, length: { maximum: 255 }
  validates :level, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 5 }
  validates :nb_solves, presence: true, numericality: { greater_or_equal_to: 0 }
  
  # OTHER METHODS

  # Return the value of the problem
  def value
    return 15*level
  end
  
  # Tell if the problem can be seen by the given user
  def can_be_seen_by(user, no_new_submission)
    return true if user.admin?
    return false if !self.online?
    return false if user.rating < 200
    return false if no_new_submission and self.submissions.where(:user => user).where.not(:status => :draft).count == 0
    if self.virtualtest_id == 0 # Not in a virtualtest: prerequisites should be completed
      self.chapters.each do |c|
        return false if !user.chap_solved?(c)
      end
    else # In a virtualtest: the user should have finished the test
      return false if user.test_status(self.virtualtest) != "finished"
    end
    return true
  end
  
  # Update the nb_solves, first_solve_time and last_solve_time of each problem (done every wednesday at 3 am (see schedule.rb))
  # NB: They are more or less maintained correct, but not when a user is deleted for instance
  def self.update_stats
    Problem.where(:online => true).each do |p|
      nb_solves = p.solvedproblems.count
      if nb_solves >= 1
        first_solve_time = p.solvedproblems.order(:resolution_time).first.resolution_time
        last_solve_time = p.solvedproblems.order(:resolution_time).last.resolution_time
      else
        first_solve_time = nil
        last_solve_time = nil
      end
      if p.nb_solves != nb_solves or p.first_solve_time != first_solve_time or p.last_solve_time != last_solve_time
        p.nb_solves = nb_solves
        p.first_solve_time = first_solve_time
        p.last_solve_time = last_solve_time
        p.save
      end
    end
  end
end

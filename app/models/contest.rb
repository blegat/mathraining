#encoding: utf-8

# == Schema Information
#
# Table name: contests
#
#  id               :integer          not null, primary key
#  number           :integer
#  description      :text
#  status           :integer          default("in_construction")
#  medal            :boolean          default(FALSE)
#  start_time       :datetime
#  end_time         :datetime
#  num_problems     :integer          default(0)
#  num_participants :integer          default(0)
#  bronze_cutoff    :integer          default(0)
#  silver_cutoff    :integer          default(0)
#  gold_cutoff      :integer          default(0)
#
include ApplicationHelper
include ContestsHelper

class Contest < ActiveRecord::Base

  enum status: {:in_construction => 0, # in construction (only visible by organizers)
                :in_progress     => 1, # online and not finished (but maybe not started)
                :in_correction   => 2, # online and finished (but not corrected)
                :completed       => 3} # online, finished, and corrected

  # BELONGS_TO, HAS_MANY

  has_many :contestscores, dependent: :destroy
  has_many :contestproblems, dependent: :destroy
  has_many :contestorganizations, dependent: :destroy
  has_many :organizers, through: :contestorganizations, source: :user
  has_many :followingcontests, dependent: :destroy
  has_many :followers, through: :followingcontests, source: :user
  
  has_one :subject

  # VALIDATIONS

  validates :status, presence: true
  validates :description, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :number, presence: true, numericality: { greater_than: 0 }
  
  # OTHER METHODS
  
  # Tells if given user is an organizer of the contest
  def is_organized_by(user)
    return organizers.include?(user)
  end
  
  # Tells if given user is a root or an organizer of the contest
  def is_organized_by_or_root(user)
    return user.root? || is_organized_by(user)
  end
  
  # Tells if given user if an admin or an organizer of the contest
  def is_organized_by_or_admin(user)
    return user.admin? || is_organized_by(user)
  end
  
  # Method called every exact hour (see schedule.rb)
  def self.check_contests_starts
    date_now_plus_1_min = DateTime.now + 1.minute # Security of 1 min in case cron job is earlier (should not happen...)
    date_in_one_day_plus_1_min = 1.day.from_now + 1.minute # idem
    Contestproblemcheck.all.order(:id).each do |c|
      p = c.contestproblem
      if p.no_reminder_sent? # Check reminder for problem published in one day
        if date_in_one_day_plus_1_min >= p.start_time
          c = p.contest
          allp = c.contestproblems.where("start_time = ?", p.start_time).order(:number).all.to_a
          allid = Array.new
          allp.each do |pp|
            pp.early_reminder_sent!
            allid.push(pp.id)
          end
          self.automatic_start_in_one_day_problem_post(allp)
          p.contest.followers.each do |u|
            UserMailer.new_followed_contestproblem(u.id, allid).deliver
          end
        end
      end
      if p.early_reminder_sent? # Check reminder for problem published now
        if date_now_plus_1_min >= p.start_time
          c = p.contest
          allp = c.contestproblems.where("start_time = ? AND end_time = ?", p.start_time, p.end_time).order(:number).all.to_a
          allp.each do |pp|
            pp.all_reminders_sent!
          end
          self.automatic_start_problem_post(allp)
        end
      end
    end
  end
  
  # Publish a post on forum to say that a problem will be published in one day
  def self.automatic_start_in_one_day_problem_post(contestproblems)
    contest = contestproblems[0].contest
    sub = contest.subject
    mes = Message.create(:subject => sub, :user_id => 0, :content => get_problems_in_one_day_forum_message(contest, contestproblems), :created_at => contestproblems[0].start_time - 1.day + (contestproblems[0].number).seconds)
    
    if mes.created_at > sub.last_comment_time # Security: should always be true
      sub.update_attributes(last_comment_time: mes.created_at, last_comment_user_id: 0)
    end
    
    sub.following_users.each do |u|
      if !contest.followers.include?(u) # Avoid to send again an email to people already following the contest
        UserMailer.new_followed_message(u.id, sub.id, -1).deliver
      end
    end
  end
  
  # Publish a post on forum to say that solutions to a problem can be sent
  def self.automatic_start_problem_post(contestproblems)
    contest = contestproblems[0].contest
    sub = contest.subject
    mes = Message.create(:subject => sub, :user_id => 0, :content => get_problems_now_forum_message(contest, contestproblems), :created_at => contestproblems[0].start_time + (contestproblems[0].number).seconds)
    
    if mes.created_at > sub.last_comment_time # Security: should always be true
      sub.update_attributes(last_comment_time: mes.created_at, last_comment_user_id: 0)
    end
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver
    end
  end
end

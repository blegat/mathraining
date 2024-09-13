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
  
  has_and_belongs_to_many :organizers, -> { distinct }, class_name: "User", join_table: :contestorganizations
  has_and_belongs_to_many :following_users, -> { distinct }, class_name: "User", join_table: :followingcontests
  
  has_one :subject
  
  # BEFORE, AFTER
  
  before_destroy { self.following_users.clear }
  before_destroy { self.organizers.clear }

  # VALIDATIONS

  validates :status, presence: true
  validates :description, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :number, presence: true, numericality: { greater_than: 0 }
  validates :bronze_cutoff, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :silver_cutoff, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :gold_cutoff, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # OTHER METHODS
  
  # Tells if given user is an organizer of the contest
  def is_organized_by(user)
    return self.organizers.include?(user)
  end
  
  # Tells if given user is a root or an organizer of the contest
  def is_organized_by_or_root(user)
    return user.root? || self.is_organized_by(user)
  end
  
  # Tells if given user if an admin or an organizer of the contest
  def is_organized_by_or_admin(user)
    return user.admin? || self.is_organized_by(user)
  end
  
  # Helper method to update problem numbers
  def update_problem_numbers
    x = 1
    self.contestproblems.order(:start_time, :end_time, :id).each do |p|
      p.update_attribute(:number, x)
      x = x+1
    end
  end
  
  # Helper method to update contest details (number of problems, start time, end time...)
  def update_details
    self.update_attribute(:num_problems, contestproblems.count)
    if self.num_problems > 0
      self.update(start_time: contestproblems.order(:start_time).first.start_time, 
                  end_time:   contestproblems.order(:end_time).last.end_time)
    else
      self.update(start_time: nil, end_time: nil)
    end
  end
  
  #  Helper method called from different locations to recompute all the contest scores
  def compute_new_contest_rankings
    # Find all users with a score > 0 in the contest
    userset = Set.new
    probs = self.contestproblems.where(:status => [:corrected, :in_recorrection])
    probs.each do |p|
      p.contestsolutions.where("score > 0 AND official = ?", false).each do |s|
        userset.add(s.user_id)
      end
    end
    
    # Delete from Contestscore the users who don't have a score (can happen if we modify a score to 0)
    self.contestscores.each do |s|
      if !userset.include?(s.user_id)
        s.destroy
      end
    end
    
    # Compute the scores of all users
    scores = Array.new
    userset.each do |u|
      score = 0
      hm = false
      probs.each do |p|
        sol = p.contestsolutions.where(:user_id => u).first
        if !sol.nil?
          score = score + sol.score
          if sol.score == 7
            hm = true
          end
        end
      end
      scores.push([-score, u, hm])
    end
    
    # Sort the scores
    scores.sort!    
    
    # Compute the ranking (and maybe medal) of each user
    give_medals = (self.medal && self.gold_cutoff > 0)
    prevscore = -1
    i = 1
    rank = 0
    scores.each do |a|
      score = -a[0]
      u = a[1]
      hm = a[2]
      if score != prevscore
        rank = i
        prevscore = score
      end
      cs = Contestscore.where(:contest => self, :user_id => u).first
      if cs.nil?
        cs = Contestscore.new(:contest => self, :user_id => u)
      end
      cs.rank = rank
      cs.score = score
      if give_medals
        if score >= self.gold_cutoff
          cs.medal = :gold_medal
        elsif score >= self.silver_cutoff
          cs.medal = :silver_medal
        elsif score >= self.bronze_cutoff
          cs.medal = :bronze_medal
        elsif hm
          cs.medal = :honourable_mention
        else
          cs.medal = :no_medal
        end
      else
        cs.medal = :undefined_medal
      end
      cs.save
      i = i+1
    end
    
    # Change some details of the contest
    self.update_attribute(:num_participants, scores.size)
    contest_fully_corrected = (self.contestproblems.where(:status => [:not_started_yet, :in_progress, :in_correction]).count == 0)
    if contest_fully_corrected
      self.completed!
    end
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
          p.contest.following_users.each do |u|
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
      sub.update(last_comment_time: mes.created_at, last_comment_user_id: 0)
    end
    
    sub.following_users.each do |u|
      if !contest.following_users.include?(u) # Avoid to send again an email to people already following the contest
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
      sub.update(last_comment_time: mes.created_at, last_comment_user_id: 0)
    end
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver
    end
  end
end

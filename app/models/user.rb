#encoding: utf-8

# == Schema Information
#
# Table name: users
#
#  id                        :integer          not null, primary key
#  first_name                :string
#  last_name                 :string
#  email                     :string
#  password_digest           :string
#  remember_token            :string
#  admin                     :boolean          default(FALSE)
#  root                      :boolean          default(FALSE)
#  created_at                :datetime         not null
#  key                       :string
#  email_confirm             :boolean          default(TRUE)
#  skin                      :integer          default(0)
#  active                    :boolean          default(TRUE)
#  see_name                  :integer          default(1)
#  sex                       :integer          default(0)
#  wepion                    :boolean          default(FALSE)
#  year                      :integer          default(0)
#  rating                    :integer          default(0)
#  last_forum_visit_time     :datetime         default(Thu, 01 Jan 2009 01:00:00.000000000 CET +01:00)
#  last_connexion_date       :date             default(Thu, 01 Jan 2009)
#  follow_message            :boolean          default(FALSE)
#  corrector                 :boolean          default(FALSE)
#  group                     :string           default("")
#  valid_name                :boolean          default(FALSE)
#  consent_time              :datetime
#  country_id                :integer
#  recup_password_date_limit :datetime
#  last_policy_read          :boolean          default(FALSE)
#  accept_analytics          :boolean          default(TRUE)
#  can_change_name           :boolean          default(TRUE)
#  correction_level          :integer          default(0)
#  corrector_color           :string
#
include ERB::Util

class CharacterValidator < ActiveModel::Validator
  def validate(record)
    a = [record.first_name, record.last_name]
    b = ["Prénom", "Nom"]
    (0..1).each do |j|
      one_letter = false
      (0..(a[j].size-1)).each do |i|
        if (User.allowed_characters.include?(a[j][i]))
          one_letter = true
        elsif (!User.allowed_special_characters.include?(a[j][i]))
          record.errors.add(:base, "#{b[j]} ne peut pas contenir le caractère #{a[j][i]}")
        end
      end
      if(not one_letter)
        record.errors.add(:base, "#{b[j]} doit contenir au moins une lettre")
      end
    end
  end
end

class ColorValidator < ActiveModel::Validator
  def validate(record)
    return if !record.admin? && !record.corrector?
    
    good_format = true
    record.corrector_color.upcase!
    c = record.corrector_color
    if c.size != 7
      good_format = false
    elsif c[0] != '#'
      good_format = false
    else
      (1..6).each do |i|
        good_format = false if !((c[i].ord >= '0'.ord && c[i].ord <= '9'.ord) || (c[i].ord >= 'A'.ord && c[i].ord <= 'F'.ord))
      end
    end
    
    if !good_format
      record.errors.add(:base, "La couleur pour les corrections doit être au format #RRGGBB avec chaque lettre entre '0' et 'F' (en hexadécimal).")
    end
  end
end

class User < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_secure_password
  
  has_many :solvedquestions, dependent: :destroy
  has_many :unsolvedquestions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :pictures
  has_many :pointspersections, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :suspicions, dependent: :destroy
  has_many :starproposals, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followed_submissions, through: :followings, source: :submission
  has_many :messages, dependent: :destroy
  has_many :takentests, dependent: :destroy
  has_many :puzzleattempts, dependent: :destroy
  has_many :sanctions, dependent: :destroy
  
  has_many :links
  has_many :discussions, through: :links # dependent: :destroy does NOT destroy the associated discussions, but only the link!
  belongs_to :country
  
  has_many :contestsolutions, dependent: :destroy
  has_many :contestscores, dependent: :destroy
  
  has_and_belongs_to_many :theories, -> { distinct }
  has_and_belongs_to_many :chapters, -> { distinct }
  has_and_belongs_to_many :followed_subjects, -> { distinct }, class_name: "Subject", join_table: :followingsubjects
  has_and_belongs_to_many :followed_contests, -> { distinct }, class_name: "Contest", join_table: :followingcontests
  has_and_belongs_to_many :followed_users, -> { distinct }, class_name: "User", join_table: :followingusers, association_foreign_key: :followed_user_id
  has_and_belongs_to_many :following_users, -> { distinct }, class_name: "User", join_table: :followingusers, foreign_key: :followed_user_id
  has_and_belongs_to_many :creating_chapters, -> { distinct }, class_name: "Chapter", join_table: :chaptercreations
  has_and_belongs_to_many :organized_contests, -> { distinct }, class_name: "Contest", join_table: :contestorganizations
  has_and_belongs_to_many :notified_submissions, -> { distinct }, class_name: "Submission", join_table: :notifs
  
  # BEFORE, AFTER

  before_validation :create_corrector_color
  before_save { self.email.downcase! }
  before_create :create_remember_token
  after_create :create_points
  before_destroy :destroy_discussions
  before_destroy { self.theories.clear }
  before_destroy { self.chapters.clear }
  before_destroy { self.followed_subjects.clear }
  before_destroy { self.followed_contests.clear }
  before_destroy { self.followed_users.clear }
  before_destroy { self.following_users.clear }
  before_destroy { self.creating_chapters.clear }
  before_destroy { self.organized_contests.clear }
  before_destroy { self.notified_submissions.clear }

  # VALIDATIONS

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  validates_with CharacterValidator
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }, on: :create
  validates :email_confirmation, presence: true, on: :create
  validates :password, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, on: :update, allow_blank: true
  validates :password_confirmation, presence: true, on: :create
  validates_confirmation_of :email, case_sensitive: false
  validates :year, presence: true
  validates_with ColorValidator
  
  # OTHER METHODS
  
  def self.allowed_characters
    Set["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "É", "Ö", "à", "á", "â", "ã", "ä", "ç", "è", "é", "ê", "ë", "î", "ï", "ñ", "ò", "ó", "ô", "ö", "ù", "ü", "š"]
  end
  
  def self.allowed_special_characters
    Set[" ", "'", "-", "."]
  end
  
  def self.limit_waiting_submissions
    return (Rails.env.production? ? 50 : 2)
  end

  # Complete name (with only initial of last name if the user asked to)
  def name
    if self.see_name == 0
      return self.shortname
    else
      return self.fullname
    end
  end

  # Complete name
  def fullname
    return "#{self.first_name} #{self.last_name}"
  end
  
  # Complete name but with only initial of last name
  def shortname
    return "#{self.first_name} #{self.last_name[0]}."
  end
  
  # Word sûr/sûre depending on the gender of the user (to ask confirmation)
  def sure
    return (self.sex == 1 ? "sûre" : "sûr")
  end

  # Tells if the user solved the given problem
  def pb_solved?(problem)
    return (self.solvedproblems.where(:problem_id => problem).count > 0)
  end

  # Tells if the user completed the given chapter
  def chap_solved?(chapter)
    return self.chapters.include?(chapter)
  end
  
  # Tells if the user completed all chapters which are prerequisite to write a submission
  def can_write_submission?
    return (self.chapters.where(:online => true, :submission_prerequisite => true).count == Chapter.where(:online => true, :submission_prerequisite => true).count)
  end
  
  # Tells if the user has already sent a new submission (not in a test) today
  def has_already_submitted_today?
    return self.submissions.where("visible = ? AND intest = ? AND created_at >= ?", true, false, Date.today.in_time_zone.to_datetime).count >= 1
  end

  # Gives the status for the given virtual test ("not_started", "in_progress", "finished")
  def test_status(virtualtest)
    x = self.takentests.where(:virtualtest => virtualtest).first
    if x.nil?
      return "not_started"
    else
      return x.status
    end
  end

  # Returns [n, d], saying there are n submissions that the user can correct + all submissions of last d days
  def num_notifications_new(levels, show_all = false)
    Groupdate.time_zone = false unless Rails.env.production?
    x = {}
    if self.admin?
      x = Submission.joins(:problem).where(:status => :waiting, :visible => true).where("problems.level in (?)", levels).group_by_day(:created_at).count
    elsif self.corrector?
      x = Submission.joins(:problem).where("problem_id IN (SELECT solvedproblems.problem_id FROM solvedproblems WHERE solvedproblems.user_id = #{self.id})").where(:status => :waiting, :visible => true).where("problems.level in (?)", levels).group_by_day(:created_at).count
    end
    y = x.sort_by(&:first)
    n = 0
    y.each do |a|
      n = n + a[1]
      if !show_all && n >= User.limit_waiting_submissions
        return [n, (Date.today - a[0]).to_i]
      end
    end
    return [n, 0]
  end

  # Gives the number of submissions with a new comment to read
  def num_notifications_update
    return followings.where(:read => false).count
  end

  # Gives the "level" of the user
  def level
    return {} if admin # Should not be used anymore with light/dark theme!
    actuallevel = nil
    Color.get_all.each do |c|
      if c.pt <= rating
        actuallevel = c
      else
        return actuallevel
      end
    end
    return {id: 0, pt: 0, color: "#FF0000", name: "Undefined", feminine_name: "Undefined"} if actuallevel.nil? # For tests, when no color exists
    return actuallevel
  end

  # Gives the number of unseen subjects on the forum
  def num_unseen_subjects(include_myself)
    if self.admin? or (self.corrector? and self.wepion?)
      req = Subject.where("last_comment_time > ?", self.last_forum_visit_time)
    elsif self.corrector?
      req = Subject.where("for_wepion = ? AND last_comment_time > ?", false, self.last_forum_visit_time)
    elsif self.wepion?
      req = Subject.where("for_correctors = ? AND last_comment_time > ?", false, self.last_forum_visit_time)
    else
      req = Subject.where("for_wepion = ? AND for_correctors = ? AND last_comment_time > ?", false, false, self.last_forum_visit_time)
    end
    
    if include_myself
      return req.count
    else
      return req.where.not(last_comment_user: self).count
    end
  end
  
  # Adapt the name of the user automatically
  def adapt_name
    (0..1).each do |j|
      if(j == 0)
        r = self.first_name
      else
        r = self.last_name
      end
      previousLetter = false
      
      (0..(r.size-1)).each do |i|
        if(r[i] =~/[[:alpha:]]/)
          if(previousLetter)
            r[i] = r[i].downcase
          end
          previousLetter = true
        else
          previousLetter = false
        end
      end
      
      while r[0] == ' '
        r = r.slice(1..-1)
      end
      
      while r[r.size-1] == ' '
        r = r.slice(0..-2)
      end
      
      if r.size == 1
        r = r + "."
      end
      
      if(j == 0)
        self.first_name = r
      else
        self.last_name = r
      end
    end
  end
  
  # Update correction level
  def update_correction_level
    num_corrections = self.followings.where("kind > 0").count
    level = 0
    a = 1
    b = 1
    while num_corrections >= b
      c = a+b
      a = b
      b = c
      level = level + 1
    end
    level = level - (Rails.env.production? ? 8 : 1)
    if self.correction_level < level
      self.update_attribute(:correction_level, level)
    end
  end
  
  # Gives the corrector prefix (if any) for the name
  def corrector_prefix
    if (self.admin? || self.corrector?) && self.correction_level > 0
      return "<span class='text-color-black-white fw-bold'><sup>#{self.correction_level}</sup></span>"
    else
      return ""
    end
  end
  
  # Gives the color class to be used for this user
  def color_class
    if self.admin?
      return "text-color-black-white";
    elsif !self.active?
      return "text-color-level-inactive";
    else
      return "text-color-level-#{self.level[:id]}";
    end
  end

  # Returns the colored name of the user:
  # name_type = 0 : to respect the user choice (full name or not)
  # name_type = 1 : to show the full name
  # name_type = 2 : to show the name with initial only for last name
  def colored_name(name_type = 0, add_corrector_prefix = true)
    goodname = self.name      if name_type == 0
    goodname = self.fullname  if name_type == 1
    goodname = self.shortname if name_type == 2
    if self.admin?
      s = (add_corrector_prefix ? self.corrector_prefix : "") + "<span class='text-color-black-white fw-bold'>#{html_escape(goodname)}</span>"
    elsif !self.corrector?
      s = "<span class='fw-bold #{self.color_class}'>#{html_escape(goodname)}</span>"
    else
      debut = goodname[0]
      fin = goodname[1..-1]
      s = (add_corrector_prefix ? self.corrector_prefix : "") + "<span class='text-color-black-white fw-bold'>#{debut}</span><span class='fw-bold #{self.color_class}'>#{html_escape(fin)}</span>"
    end
    return s.html_safe
  end

  # Returns the colored linked name of the user (see colored_name for explanations about name_type)
  def linked_name(name_type = 0, add_corrector_prefix = true)
    if !self.active?
      s = self.colored_name(name_type)
    else
      # Note: We give a color to the "a" so that the link is underlined with this color when it is hovered/clicked
      s = (add_corrector_prefix ? self.corrector_prefix : "") + "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' class='#{self.color_class}'>" + self.colored_name(name_type, false) + "</a>"
    end
    return s.html_safe
  end
  
  # Gives the last ban of the user
  def last_ban
    return self.sanctions.where(:sanction_type => :ban).order(:start_time).last
  end
  
  # Gives the last sanction of the user not allowing him to send new submissions
  def last_no_submission_sanction
    return self.sanctions.where(:sanction_type => :no_submission).order(:start_time).last
  end
  
  # Tells if the user currently has the sanction to not send new submissions
  def has_no_submission_sanction
    sanction = self.last_no_submission_sanction
    return !sanction.nil? && sanction.end_time > DateTime.now
  end
  
  # Create a new random token, to automatically sign out the user from everywhere
  def update_remember_token
    self.create_remember_token
    self.save
  end

  # Create a random token
  def create_remember_token
    begin
      self.remember_token = SecureRandom.urlsafe_base64
    end while User.exists?(:remember_token => self.remember_token)
  end
  
  # Create a random color (for correctors) or remove it (for non-correctors)
  def create_corrector_color
    if self.admin? || self.corrector?
      if self.corrector_color.nil?
        self.corrector_color = "#"
        (0..5).each do |i|
          r = (i % 2 == 1 ? rand(0..15) : rand(5..12));
          x = (r < 10 ? ("0".ord + r).chr : ("A".ord + r-10).chr)
          self.corrector_color = self.corrector_color + x
        end
      end
    elsif !self.corrector_color.nil?
      self.corrector_color = nil
    end
  end
  
  # Deletes the user that never came on the website (done very day at 2 am (see schedule.rb))
  def self.delete_unconfirmed
    # Users that have not confirmed their email after one week
    oneweekago = Date.today - 7
    User.where("email_confirm = ? AND created_at < ?", false, oneweekago).each do |u|
      u.destroy
    end
    # Users having confirmed their email but that never came on the website after one month (rating = 0 should be redundant))
    onemonthago = Date.today - 31
    User.where("admin = ? AND rating = ? AND created_at < ? AND last_connexion_date < ?", false, 0, onemonthago, "2012-01-01").each do |u|
      u.destroy
    end
  end
  
  # Recompute all scores
  def self.recompute_scores(check_only = true) 
    all_warnings = []
    problem_scores = Array.new
    question_scores = Array.new
    problem_scores_by_section = Array.new
    question_scores_by_section = Array.new
    Section.all.each do |s|
      real_max_score = 0
      unless s.fondation
        problem_scores_by_section[s.id] = Array.new
        question_scores_by_section[s.id] = Array.new
        real_max_score = 15 * s.problems.where(:online => true).sum(:level) + 3 * Question.where(:chapter_id => s.chapters, :online => true).sum(:level)
      end
      if s.max_score != real_max_score
        all_warnings.push("Section " + s.id.to_s + " should have max score " + real_max_score.to_s + " instead of " + s.max_score.to_s + "!")
        unless check_only
          s.update_attribute(:max_score, real_max_score)
        end
      end
    end
    
    User.joins(solvedproblems: :problem).select("users.id, problems.section_id, 15*sum(problems.level) AS x").group("users.id, problems.section_id").each do |u|
      problem_scores_by_section[u.section_id][u.id] = u.x
      problem_scores[u.id] = 0 if problem_scores[u.id].nil?
      problem_scores[u.id] += u.x
    end
    
    User.joins(solvedquestions: [{question: [{chapter: :section}]}]).where("sections.fondation = ?", false).select("users.id, chapters.section_id, 3*sum(questions.level) AS x").group("users.id, chapters.section_id").each do |u|
      question_scores_by_section[u.section_id][u.id] = u.x
      question_scores[u.id] = 0 if question_scores[u.id].nil?
      question_scores[u.id] += u.x
    end
    
    User.where(:admin => false, :active => true).select("users.*").each do |u|
      current_score = u.rating
      problem_score = problem_scores[u.id]
      problem_score = 0 if problem_score.nil?
      question_score = question_scores[u.id]
      question_score = 0 if question_score.nil?
      real_score = problem_score + question_score
      if current_score != real_score
        all_warnings.push("User " + u.id.to_s + " should have score " + real_score.to_s + " instead of " + current_score.to_s + "!")
        unless check_only
          u.update_attribute(:rating, real_score)
        end
      end
    end
    
    Pointspersection.joins(:section).each do |pps|
      current_score = pps.points
      problem_score = problem_scores_by_section[pps.section_id][pps.user_id]
      problem_score = 0 if problem_score.nil?
      question_score = question_scores_by_section[pps.section_id][pps.user_id]
      question_score = 0 if question_score.nil?
      real_score = problem_score + question_score
      if current_score != real_score
        all_warnings.push("User " + pps.user_id.to_s + " should have score " + real_score.to_s + " instead of " + current_score.to_s + " for section " + pps.section_id.to_s + "!")
        unless check_only
          pps.update_attribute(:points, real_score)
        end
      end
    end
    
    unless check_only
      Globalstatistic.get.update_all
    end
    
    return all_warnings
  end
  
  private

  # Create the points per section associated to the user
  def create_points
    # We can probably do that with ruby? (We want only one request because it is done very often during testing)
    ActiveRecord::Base.connection.execute("INSERT INTO pointspersections (user_id, section_id, points) SELECT '#{self.id}', id, '0' FROM sections WHERE fondation = 'false';")
  end

  # Delete all discussions of the user
  def destroy_discussions
    self.discussions.each do |d|
      d.destroy
    end
  end
end

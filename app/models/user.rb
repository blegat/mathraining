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
#  updated_at                :datetime         not null
#  key                       :string
#  email_confirm             :boolean          default(TRUE)
#  skin                      :integer          default(0)
#  active                    :boolean          default(TRUE)
#  see_name                  :integer          default(1)
#  sex                       :integer          default(0)
#  wepion                    :boolean          default(FALSE)
#  year                      :integer          default(0)
#  rating                    :integer          default(0)
#  last_forum_visit_time     :datetime         default(Thu, 01 Jan 2009 01:00:00 CET +01:00)
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
#
include ERB::Util

class NoNumberValidator < ActiveModel::Validator
  def validate(record)
    [record.first_name, record.last_name].each do |r|
      ok = false
      (0..(r.size-1)).each do |i|
        if(r[i] =~ /[[:digit:]]/)
          record.errors[:base] << "Prénom et Nom ne peuvent pas contenir de chiffres"
        end
        if(r[i] =~/[[:alpha:]]/)
          ok = true
        end
      end
      if(not ok)
        record.errors[:base] << "Prénom et Nom doivent contenir au moins une lettre"
      end
    end
  end
end

class User < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_secure_password
  has_and_belongs_to_many :theories
  has_and_belongs_to_many :chapters
  has_many :solvedquestions, dependent: :destroy
  has_many :solvedproblems, dependent: :destroy
  has_many :pictures
  has_many :pointspersections, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followed_submissions, through: :followings, source: :submission
  has_many :notifs, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :takentests, dependent: :destroy
  
  has_many :links
  has_many :discussions, through: :links # dependent: :destroy does NOT destroy the associated discussions, but only the link!
  belongs_to :country

  has_many :followingsubjects, dependent: :destroy
  has_many :followed_subjects, through: :followingsubjects, source: :subject

  has_many :followingusers, dependent: :destroy
  has_many :followed_users, :class_name => "User", through: :followingusers, foreign_key: "followed_user_id"
  has_many :backwardfollowingusers, class_name: "Followinguser", dependent: :destroy, foreign_key: "followed_user_id"
  
  has_many :chaptercreations, dependent: :destroy
  has_many :creating_chapters, through: :chaptercreations, source: :chapter
  
  has_many :contestorganizations, dependent: :destroy
  has_many :organized_contests, through: :contestorganizations, source: :contest
  has_many :followingcontests, dependent: :destroy
  has_many :followed_contests, through: :followingcontests, source: :contest
  
  has_many :contestsolutions, dependent: :destroy
  has_many :contestscores, dependent: :destroy
  
  # BEFORE, AFTER

  before_save { self.email.downcase! }
  before_create :create_remember_token
  after_create :create_points
  before_destroy :destroy_discussions

  # VALIDATIONS

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  validates_with NoNumberValidator
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }, on: :create
  validates :email_confirmation, presence: true, on: :create
  validates :password, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, on: :update, allow_blank: true
  validates :password_confirmation, presence: true, on: :create
  validates_confirmation_of :email, case_sensitive: false
  validates :year, presence: true
  validates :country, presence: true
  
  # OTHER METHODS

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

  # Tells if the user solved the given problem
  def pb_solved?(problem)
    return (self.solvedproblems.where(:problem_id => problem).count > 0)
  end

  # Tells if the user completed the given chapter
  def chap_solved?(chapter)
    return self.chapters.include?(chapter)
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

  # Gives the number of submissions that the user can correct
  def num_notifications_new
    if sk.admin
      return Submission.where(:status => :waiting, :visible => true).count
    elsif sk.corrector
      return Submission.where("problem_id IN (SELECT solvedproblems.problem_id FROM solvedproblems WHERE solvedproblems.user_id = #{sk.id})").where(:status => :waiting, :visible => true).count
    end
  end

  # Gives the number of submissions with a new comment to read
  def num_notifications_update
    return followed_submissions.where(followings: { read: false }).count
  end

  # Gives the "level" of the user
  def level
    if admin
      return {color:"#000000"}
    elsif !active
      return {color:"#BBBB00"}
    else
      actuallevel = nil
      if $allcolors.nil?
        $allcolors = Color.order(:pt).to_a
      end
      $allcolors.each do |c|
        if c.pt <= rating
          actuallevel = c
        else
          return actuallevel
        end
      end
      return actuallevel
    end
  end

  # Gives the number of unseen subjects on the forum
  def num_unseen_subjects(include_myself)
    if include_myself
      if self.admin? or (self.corrector? and self.wepion?)
        return Subject.where("last_comment_time > ?", self.last_forum_visit_time).count
      elsif self.corrector?
        return Subject.where("for_wepion = ? AND last_comment_time > ?", false, self.last_forum_visit_time).count
      elsif self.wepion?
        lastsubjects = Subject.where("for_correctors = ? AND last_comment_time > ?", false, self.last_forum_visit_time).count
      else
        lastsubjects = Subject.where("for_wepion = ? AND for_correctors = ? AND last_comment_time > ?", false, false, self.last_forum_visit_time).count
      end
    else
      if self.admin? or (self.corrector? and self.wepion?)
        return Subject.where("last_comment_time > ?", self.last_forum_visit_time).where.not(last_comment_user: self.sk).count
      elsif self.corrector?
        return Subject.where("for_wepion = ? AND last_comment_time > ?", false, self.last_forum_visit_time).where.not(last_comment_user: self.sk).count
      elsif self.wepion?
        lastsubjects = Subject.where("for_correctors = ? AND last_comment_time > ?", false, self.last_forum_visit_time).where.not(last_comment_user: self.sk).count
      else
        lastsubjects = Subject.where("for_wepion = ? AND for_correctors = ? AND last_comment_time > ?", false, false, self.last_forum_visit_time).where.not(last_comment_user: self.sk).count
      end
    end
  end

  # Gives the skin of the user: current_user.sk must be used almost everywhere
  def sk
    if self.admin? && self.skin != 0
      return User.find(self.skin)
    else
      return self
    end
  end

  # Tells if the user is not in his own skin
  def other
    if self.admin? && self.skin != 0
      return true
    else
      return false
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
      
      while(r[0] == ' ')
        r = r.slice(1..-1)
      end
      
      while(r[r.size-1] == ' ')
        r = r.slice(0..-2)
      end
      
      if(r.size == 1)
        r = r + "."
      end
      
      if(j == 0)
        self.first_name = r
      else
        self.last_name = r
      end
    end
  end

  # Returns the colored name of the user:
  # name_type = 0 : to respect the user choice (full name or not)
  # name_type = 1 : to show the full name
  # name_type = 2 : to show the name with initial only for last name
  def colored_name(name_type = 0)
    goodname = self.name      if name_type == 0
    goodname = self.fullname  if name_type == 1
    goodname = self.shortname if name_type == 2
    if !self.corrector?
      return "<span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(goodname)}</span>"
    else
      debut = goodname[0]
      fin = goodname[1..-1]
      return "<span style='color:black; font-weight:bold;'>#{debut}</span><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(fin)}</span>"
    end
  end

  # Returns the colored linked name of the user (see colored_name for explanations about name_type)
  def linked_name(name_type = 0)
    if !self.active?
      return self.colored_name(name_type)
    else
      # Note: We give a color to the "a" so that the link is underlined with this color when it is hovered/clicked
      return "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' style='color:#{self.level[:color]}'>" + self.colored_name(name_type) + "</a>"
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

  private

  # Create a random token
  def create_remember_token
    begin
      self.remember_token = SecureRandom.urlsafe_base64
    end while User.exists?(:remember_token => self.remember_token)
  end

  # Create the points per section associated to the user
  def create_points
    Section.all.to_a.each do |s|
      newpoint = Pointspersection.new
      newpoint.points = 0
      newpoint.section_id = s.id
      self.pointspersections << newpoint
    end
  end

  # Delete all discussions of the user
  def destroy_discussions
    self.discussions.each do |d|
      d.destroy
    end
  end
end

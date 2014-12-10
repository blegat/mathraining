#encoding: utf-8
# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  first_name      :string(255)
#  last_name       :string(255)
#  email           :string(255)
#  password_digest :string(255)
#  remember_token  :string(255)
#  admin           :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name,
    :password, :password_confirmation, :admin, :root,
    :email_confirm, :key, :skin
  has_secure_password
  has_and_belongs_to_many :theories
  has_and_belongs_to_many :chapters, -> {uniq}
  has_many :solvedexercises, dependent: :destroy
  has_many :exercises, through: :solvedexercises
  has_many :solvedqcms, dependent: :destroy
  has_many :qcms, through: :solvedqcms
  has_many :solvedproblems, dependent: :destroy
  has_many :problems, through: :solvedproblems
  has_many :pictures
  has_one :point, dependent: :destroy
  has_many :pointspersections, dependent: :destroy
  has_many :submissions, dependent: :destroy

  has_many :followings, dependent: :destroy
  has_many :followed_submissions, through: :followings, source: :submission
  has_many :notifs, dependent: :destroy

  has_many :subjects, dependent: :destroy
  has_many :messages, dependent: :destroy

  has_many :followingsubjects, dependent: :destroy
  has_many :followed_subjects, through: :followingsubjects, source: :subject

  before_save { self.email.downcase! }
  before_save :create_remember_token
  after_create :create_points

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
	  uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }
  # presence: true <- commented to avoid
  # duplication of error message with confirmation
  validates :password_confirmation, presence: true

  def name
    "#{self.first_name} #{self.last_name}"
  end

  def solved?(problem)
    return problem.users.include?(self)
  end

  def notifications_new
    Submission.where("status = ?", 0)
  end

  def notifications_update
    #followed_submissions.where(submissions: { status: 3 }, followings: { read: false })
    # If another admin answer, it must still stay unread
    followed_submissions.where(followings: { read: false })
  end

  def level
    if admin
      return {color:"#000000"}
    end
    actualrating = point.rating
    i = 0
    actuallevel = Color.order(:pt).first
    Color.order(:pt).to_a.each do |c|
      if c.pt <= actualrating
        actuallevel = c
      end
      i = i+1
    end
    return actuallevel
  end

  def see_forum
    lastdate = '2009-01-01 00:00:00'

    if self.admin?
      return true if Subject.order("lastcomment DESC").count == 0
      lastdate = Subject.order("lastcomment DESC").first.lastcomment
    else
      return true if Subject.where(admin: false).order("lastcomment DESC").count == 0
      lastdate = Subject.where(admin: false).order("lastcomment DESC").first.lastcomment
    end
    if lastdate < self.point.forumseen
      return true
    else
      return false
    end
  end
  
  def combien_forum
    if self.admin?
      return Subject.where("lastcomment > ?", self.point.forumseen).count
    else
      return Subject.where("admin = ? AND lastcomment > ?", false, self.point.forumseen).count
    end
  end

  def sk
    if self.admin? && self.skin != 0
      return User.find(self.skin)
    else
      return self
    end
  end

  def other
    if self.admin? && self.skin != 0
      return true
    else
      return false
    end
  end

  private


  def create_remember_token
    self.remember_token = SecureRandom.urlsafe_base64
  end
  def create_points
    newpoint = Point.new
    newpoint.rating = 0
    self.point = newpoint

    Section.all.to_a.each do |s|
      newpoint = Pointspersection.new
      newpoint.points = 0
      newpoint.section_id = s.id
      self.pointspersections << newpoint
    end
  end
end

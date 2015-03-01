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
#  root            :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  key             :string(255)
#  email_confirm   :boolean
#  skin            :integer
#  active          :boolean
#  seename         :integer
#  sex             :integer
#  wepion          :boolean
#

class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :admin, :root, :email_confirm, :key, :skin, :seename, :sex, :wepion, :country, :year, :rating, :forumseen

  # BELONGS_TO, HAS_MANY

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
  has_many :pointspersections, dependent: :destroy
  has_many :submissions, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followed_submissions, through: :followings, source: :submission
  has_many :notifs, dependent: :destroy
  has_many :subjects, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :followingsubjects, dependent: :destroy
  has_many :followed_subjects, through: :followingsubjects, source: :subject

  # BEFORE, AFTER

  before_save { self.email.downcase! }
  before_create :create_remember_token
  after_create :create_points

  # VALIDATIONS

  validates :first_name, presence: true, length: { maximum: 32 }
  validates :last_name, presence: true, length: { maximum: 32 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, format: { with: VALID_EMAIL_REGEX }, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, on: :create
  validates :password, length: { minimum: 6 }, on: :update, allow_blank: true
  validates :password_confirmation, presence: true, on: :create

  # Nom complet, avec seulement l'initiale s'il faut
  def name
    if self.seename == 0
      "#{self.first_name} #{self.last_name[0]}."
    else
      "#{self.first_name} #{self.last_name}"
    end
  end

  # Nom complet
  def fullname
    "#{self.first_name} #{self.last_name}"
  end

  # Devrait ne plus être utilisé : on privilégie les deux suivants meilleurs en complexité
  def solved?(x)
    return x.users.include?(self)
  end

  def pb_solved?(problem)
    return self.problems.include?(problem)
  end

  def chap_solved?(chapter)
    return self.chapters.include?(chapter)
  end

  def solution(problem)
    s = self.solvedproblems.where(:problem_id => problem).first
    return s;
  end

  # Rend le statut pour un certain test virtuel
  def status(virtualtest)
    x = Takentest.find_by(user_id: self.id, virtualtest_id: virtualtest)
    if x.nil?
      return -1
    else
      return x.status
    end
  end

  # Rend les notifications
  def notifications_new
    Submission.where(status: 0, visible: true)
  end

  # Rend les notifications pour nouveau commentaire
  def notifications_update
    followed_submissions.where(followings: { read: false })
  end

  # Rend le niveau de l'utilisateur
  def level
    if admin
      return {color:"#000000"}
    end
    i = 0
    actuallevel = Color.order(:pt).first
    Color.order(:pt).to_a.each do |c|
      if c.pt <= rating
        actuallevel = c
      end
      i = i+1
    end

    if actuallevel.nil? # Juste pour les tests car je ne sais pas comment initialiser :-(
      color = Color.new
      color.pt = 0
      color.color = "#AAAAAA"
      color.font_color = "#AAAAAA"
      color.name = "test"
      color.femininename = "test"
      color.save
      actuallevel = Color.order(:pt).first
    end

    return actuallevel
  end

  # Rend le nombre de nouveaux messages sur le forum
  def combien_forum
    lastsubjects = Array.new
    compteur = 0
    if self.admin?
      lastsubjects = Subject.where("lastcomment > ?", self.forumseen)
    elsif self.wepion?
      lastsubjects = Subject.where("admin = ? AND lastcomment > ?", false, self.forumseen)
    else
      lastsubjects = Subject.where("wepion = ? AND admin = ? AND lastcomment > ?", false, false, self.forumseen)
    end
    lastsubjects.each do |s|
      m = s.messages.order(:id).last
      if m.nil?
      m = s
      end
      if m.user.id != self.id
        compteur = compteur+1
      end
    end
    return compteur
  end

  # Rend la peau de l'utilisateur : current_user.sk à mettre quasi partout
  def sk
    if self.admin? && self.skin != 0
      return User.find(self.skin)
    else
      return self
    end
  end

  # Rend true si l'utilisateur n'est pas dans sa propre peau
  def other
    if self.admin? && self.skin != 0
      return true
    else
      return false
    end
  end

  private

  # Créer un token aléatoire
  def create_remember_token
    begin
    self.remember_token = SecureRandom.urlsafe_base64
    end while User.exists?(:remember_token => self.remember_token)
  end

  # Créer les points associés à l'utilisateur
  def create_points
    Section.all.to_a.each do |s|
      newpoint = Pointspersection.new
      newpoint.points = 0
      newpoint.section_id = s.id
      self.pointspersections << newpoint
    end
  end
end

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
#  seename                   :integer          default(1)
#  sex                       :integer          default(0)
#  wepion                    :boolean          default(FALSE)
#  year                      :integer          default(0)
#  rating                    :integer          default(0)
#  forumseen                 :datetime         default(Thu, 01 Jan 2009 01:00:00 CET +01:00)
#  last_connexion            :date             default(Thu, 01 Jan 2009)
#  follow_message            :boolean          default(FALSE)
#  corrector                 :boolean          default(FALSE)
#  group                     :string           default("")
#  valid_name                :boolean          default(FALSE)
#  consent_date              :datetime
#  country_id                :integer
#  recup_password_date_limit :datetime
#  last_policy_read          :boolean          default(FALSE)
#  accept_analytics          :boolean          default(TRUE)
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
  has_many :followingsubjects, dependent: :destroy
  has_many :followed_subjects, through: :followingsubjects, source: :subject
  has_many :links
  has_many :discussions, through: :links # dependent: :destroy does NOT destroy the associated discussions, but only the link!
  belongs_to :country

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

  # Nom complet, avec seulement l'initiale s'il faut
  def name
    if self.seename == 0
      self.shortname
    else
      self.fullname
    end
  end

  # Nom complet
  def fullname
    "#{self.first_name} #{self.last_name}"
  end
  
  # Nom complet avec seulement l'initiale
  def shortname
    "#{self.first_name} #{self.last_name[0]}."
  end

  # Devrait ne plus être utilisé : on privilégie les deux suivants meilleurs en complexité
  def solved?(x)
    return x.users.include?(self)
  end

  def pb_solved?(problem)
    return (self.solvedproblems.where(:problem_id => problem).count > 0)
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
    x = Takentest.where(:user_id => self.id, :virtualtest_id => virtualtest).first
    if x.nil?
      return -1
    else
      return x.status
    end
  end

  # Rend les notifications
  def notifications_new
    if sk.admin
      Submission.where(status: 0, visible: true)
    elsif sk.corrector
      newsub = Array.new
      Submission.where(status: 0, visible: true).each do |s|
        if sk.pb_solved?(s.problem)
          newsub.push(s)
        end
      end
      newsub
    end
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
    actuallevel = nil
    $allcolors.each do |c|
      if c.pt <= rating
        actuallevel = c
      else
        return actuallevel
      end
    end

    return actuallevel
  end

  # Rend le nombre de nouveaux messages sur le forum
  def combien_forum(include_myself)
    if include_myself
      if self.admin? or (self.corrector? and self.wepion?)
        return Subject.where("lastcomment > ?", self.forumseen).count
      elsif self.corrector?
        return Subject.where("wepion = ? AND lastcomment > ?", false, self.forumseen).count
      elsif self.wepion?
        lastsubjects = Subject.where("admin = ? AND lastcomment > ?", false, self.forumseen).count
      else
        lastsubjects = Subject.where("wepion = ? AND admin = ? AND lastcomment > ?", false, false, self.forumseen).count
      end
    else
      if self.admin? or (self.corrector? and self.wepion?)
        return Subject.where("lastcomment > ?", self.forumseen).where.not(lastcomment_user: self.sk).count
      elsif self.corrector?
        return Subject.where("wepion = ? AND lastcomment > ?", false, self.forumseen).where.not(lastcomment_user: self.sk).count
      elsif self.wepion?
        lastsubjects = Subject.where("admin = ? AND lastcomment > ?", false, self.forumseen).where.not(lastcomment_user: self.sk).count
      else
        lastsubjects = Subject.where("wepion = ? AND admin = ? AND lastcomment > ?", false, false, self.forumseen).where.not(lastcomment_user: self.sk).count
      end
    end
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

  # name_type = 0 : to respect the user choice (full name or not)
  # name_type = 1 : to show the full name
  # name_type = 2 : to show the name with initial only for last name
  def colored_name(name_type = 0)
    if !self.active?
      return "<span style='color:#BBBB00; font-weight:bold;'>Compte supprimé</span>"
    else
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
  end

  def linked_name(name_type = 0)
    if !self.active?
      return "<span style='color:#BBBB00; font-weight:bold;'>Compte supprimé</span>"
    else
      goodname = self.name      if name_type == 0
      goodname = self.fullname  if name_type == 1
      goodname = self.shortname if name_type == 2
      if !self.corrector?
        return "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' style='color:#{self.level[:color]};'><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(goodname)}</span></a>"
      else
        debut = goodname[0]
        fin = goodname[1..-1]
        return "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' style='color:#{self.level[:color]};'><span style='color:black; font-weight:bold;'>#{debut}</span><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(fin)}</span></a>"
      end
    end
  end
  
  # A utiliser en ligne de commande (TODO: Changer cette stratégie car inutilisable avec 5000 utilisateurs!)
  def self.compute_scores
    newrating = Array.new
    newpartial = Array.new
    existpartial = Array.new
    question_value = Array.new
    question_section = Array.new
    problem_value = Array.new
    problem_section = Array.new
    sectionid = Array.new
    n_section = Section.count
    max_score = Array.new

    (1..n_section).each do |i|
      newpartial[i] = Array.new
      existpartial[i] = Array.new
      max_score[i] = 0
    end

    User.all.each do |u|
      newrating[u.id] = 0
      (1..n_section).each do |i|
        newpartial[i][u.id] = 0
        existpartial[i][u.id] = false
      end
    end

    Pointspersection.all.each do |p|
      existpartial[p.section_id][p.user_id] = true
    end

    User.all.each do |u|
      (1..n_section).each do |i|
        if !existpartial[i][u.id]
          newpoint = Pointspersection.new
          newpoint.points = 0
          newpoint.section_id = i
          user.pointspersections << newpoint
        end
      end
    end

    Chapter.all.each do |c|
      sectionid[c.id] = c.section_id
    end
    
    Question.all.each do |q|
      question_value[q.id] = q.value
      question_section[q.id] = sectionid[q.chapter_id]
      max_score[sectionid[q.chapter_id]] = max_score[sectionid[q.chapter_id]] + q.value if q.online
    end

    Problem.all.each do |p|
      problem_value[p.id] = p.value
      problem_section[p.id] = p.section_id
      max_score[p.section_id] = max_score[p.section_id] + p.value if p.online
    end

    Solvedquestion.all.each do |q|
      if q.correct
        pt = question_value[q.question_id]
        u = q.user_id
        s = question_section[q.question_id]
        newrating[u] = newrating[u] + pt
        newpartial[s][u] = newpartial[s][u] + pt
      end
    end

    Solvedproblem.all.each do |p|
      pt = problem_value[p.problem_id]
      u = p.user_id
      s = problem_section[p.problem_id]
      newrating[u] = newrating[u] + pt
      newpartial[s][u] = newpartial[s][u] + pt
    end

    warning = ""
    
    Section.all.each do |s|
      if(max_score[s.id] != s.max_score)
        warning = warning + "Le score maximal de la section #{s.id} va changer : #{max_score[s.id]} au lieu de #{s.max_score}. "
      else
        max_score[s.id] = nil
      end
    end

    Pointspersection.all.each do |p|
      if newpartial[p.section_id][p.user_id] != p.points
        warning = warning + "Le rating de ... (#{p.user_id}) pour la section #{p.section_id} va changer : #{newpartial[p.section_id][p.user_id]} au lieu de #{p.points}. "
      else
        newpartial[p.section_id][p.user_id] = nil
      end
    end

    User.all.each do |u|
      if newrating[u.id] != u.rating
        warning = warning + "Le rating de #{u.name} (#{u.id}) va changer : #{newrating[u.id]} au lieu de #{u.rating}. "
      else
        newrating[u.id] = nil
      end
    end
    
    return [warning, max_score, newrating, newpartial]
  end
  
  # A utiliser en ligne de commande, après la fonction précédente et après avoir vérifié le warning... Pour vérifier qu'il n'y a eu aucun changement de score pendant l'exécution des fonctions, on pourra réutiliser compute_scores et vérifier que le warning est vide...
  def self.apply_scores(quadruple)
    max_score = quadruple[1]
    newrating = quadruple[2]
    newpartial = quadruple[3]
    
    Section.all.each do |s|
      if ( !max_score[s.id].nil? and max_score[s.id] != s.max_score )
        s.max_score = max_score[s.id]
        s.save
      end
    end
    
    Pointspersection.all.each do |p|
      if ( !newpartial[p.section_id][p.user_id].nil? and newpartial[p.section_id][p.user_id] != p.points )
        p.points = newpartial[p.section_id][p.user_id]
        p.save
      end
    end

    User.all.each do |u|
      if ( !newrating[u.id].nil? and newrating[u.id] != u.rating )
        u.rating = newrating[u.id]
        u.save
      end
    end
  end
  
  # Supprime les utilisateurs n'étant jamais venus (fait tous les jours à 2 heures du matin (voir schedule.rb))
  def self.delete_unconfirmed
    # Utilisateurs n'ayant pas confirmé leur e-mail après une semaine
    oneweekago = Date.today - 7
    User.where("email_confirm = ? AND created_at < ?", false, oneweekago).each do |u|
      u.destroy
    end
    # Utilisateurs ayant confirmé mais n'étant jamais venu après un mois (rating = 0 est normalement redondant)
    onemonthago = Date.today - 31
    User.where("admin = ? AND rating = ? AND created_at < ? AND last_connexion < ?", false, 0, onemonthago, "2012-01-01").each do |u|
      u.destroy
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

  # Détruire les discussions de cet utilisateur
  def destroy_discussions
    self.discussions.each do |d|
      d.destroy
    end
  end
end

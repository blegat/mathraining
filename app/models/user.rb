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
#  last_connexion  :date
#  follow_message  :boolean
#  valid_name      :boolean
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
  # attr_accessible :email, :first_name, :last_name, :password, :password_confirmation, :admin, :root, :email_confirm, :key, :skin, :seename, :sex, :wepion, :country, :year, :rating, :forumseen, :last_connexion, :follow_message

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
  
  has_many :chaptercreations, dependent: :destroy
  has_many :creating_chapters, through: :chaptercreations, source: :chapter
  
  has_many :contestorganizations, dependent: :destroy
  has_many :organized_contests, through: :contestorganizations, source: :contest
  has_many :followingcontests, dependent: :destroy
  has_many :followed_contests, through: :followingcontests, source: :contest
  
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
  validates_confirmation_of :email
  validates :year, presence: true
  validates :country, presence: true

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
    i = 0
    actuallevel = nil
    $allcolors.each do |c|
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
    compteur = 0
    update_date = false
    if self.admin? or (self.corrector? and self.wepion?)
      lastsubjects = Subject.where("lastcomment > ?", self.forumseen)
    elsif self.corrector?
      lastsubjects = Subject.where("wepion = ? AND lastcomment > ?", false, self.forumseen)
    elsif self.wepion?
      lastsubjects = Subject.where("admin = ? AND lastcomment > ?", false, self.forumseen)
    else
      lastsubjects = Subject.where("wepion = ? AND admin = ? AND lastcomment > ?", false, false, self.forumseen)
    end
    lastsubjects.each do |s|
      m = s.messages.order(:created_at).last || s
      if m.user_id != self.id
        compteur = compteur+1
      end
      update_date = true
    end
    return [compteur, update_date]
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
      
      if(j == 0)
        self.first_name = r
      else
        self.last_name = r
      end
    end
  end

  def colored_name(fullname = false)
    if !self.active?
      return "<span style='color:#BBBB00; font-weight:bold;'>Compte supprimé</span>"
    elsif !self.corrector?
      return "<span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(self.name) unless fullname}#{html_escape(self.fullname) if fullname}</span>"
    else
      debut = self.name[0]
      fin = self.name[1..-1] unless fullname
      fin = self.fullname[1..-1] if fullname
      return "<span style='color:black; font-weight:bold;'>#{debut}</span><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(fin)}</span>"
    end
  end

  def linked_name(fullname = false)
    if !self.active?
      return "<span style='color:#BBBB00; font-weight:bold;'>Compte supprimé</span>"
    elsif !self.corrector?
      return "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' style='color:#{self.level[:color]};'><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(self.name)}</span></a>"
    else
      debut = self.name[0]
      fin = self.name[1..-1] unless fullname
      fin = self.fullname[1..-1] if fullname
      return "<a href='#{Rails.application.routes.url_helpers.user_path(self)}' style='color:#{self.level[:color]};'><span style='color:black; font-weight:bold;'>#{debut}</span><span style='color:#{self.level[:color]}; font-weight:bold;'>#{html_escape(fin)}</span></a>"
    end
  end
  
  # A utiliser en ligne de commande
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
      end
    end

    Pointspersection.all.each do |p|
      if newpartial[p.section_id][p.user_id] != p.points
        warning = warning + "Le rating de ... (#{p.user_id}) pour la section #{p.section_id} va changer : #{newpartial[p.section_id][p.user_id]} au lieu de #{p.points}. "
      end
    end

    User.all.each do |u|
      if newrating[u.id] != u.rating
        warning = warning + "Le rating de #{u.name} (#{u.id}) va changer : #{newrating[u.id]} au lieu de #{u.rating}. "
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
      if(max_score[s.id] != s.max_score)
        s.max_score = max_score[s.id]
        s.save
      end
    end
    
    Pointspersection.all.each do |p|
      if newpartial[p.section_id][p.user_id] != p.points
        p.points = newpartial[p.section_id][p.user_id]
        p.save
      end
    end

    User.all.each do |u|
      if newrating[u.id] != u.rating
        u.rating = newrating[u.id]
        u.save
      end
    end
  end
  
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

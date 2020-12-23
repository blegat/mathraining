#encoding: utf-8
# == Schema Information
#
# Table name: contests
#
#  id             :integer          not null, primary key
#  number         :integer
#  description    :text
#  status         :integer
#  medal          :boolean
#
# status = 0 --> in construction
# status = 1 --> online and not finished
# status = 2 --> online and finished

include ApplicationHelper

class Contest < ActiveRecord::Base
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
  
  def is_organized_by(user)
    return (!user.nil? && organizers.include?(user.sk))
  end
  
  def is_organized_by_or_root(user)
    return ((!user.nil? && user.sk.root?) || is_organized_by(user))
  end
  
  def is_organized_by_or_admin(user)
    return ((!user.nil? && user.sk.admin?) || is_organized_by(user))
  end
  
  # Méthode appelée toutes les heures piles (voir schedule.rb)
  def self.check_contests_starts
    sleep
    date_now_plus_1_min = DateTime.now + 1.minute # security of 1 min in case cron job is earlier (should not happen...)
    date_in_one_day_plus_1_min = 1.day.from_now + 1.minute # idem
    Contestproblemcheck.all.order(:id).each do |c|
      p = c.contestproblem
      if p.reminder_status == 0 # Check reminder for problem published in one day
        if date_in_one_day_plus_1_min >= p.start_time
          c = p.contest
          allp = c.contestproblems.where("start_time = ?", p.start_time).order(:number).all.to_a
          allid = Array.new
          allp.each do |pp|
            pp.reminder_status = 1
            pp.save
            allid.push(pp.id)
          end
          self.automatic_start_in_one_day_problem_post(allp)
          p.contest.followers.each do |u|
            UserMailer.new_followed_contestproblem(u.id, allid).deliver if Rails.env.production?
          end
        end
      end
      if p.reminder_status == 1 # Check reminder for problem published now
        if date_now_plus_1_min >= p.start_time
          c = p.contest
          allp = c.contestproblems.where("start_time = ? AND end_time = ?", p.start_time, p.end_time).order(:number).all.to_a
          allp.each do |pp|
            pp.reminder_status = 2
            pp.save
          end
          self.automatic_start_problem_post(allp)
        end
      end
    end
  end
  
  # Publish a post on forum to say that problem will be published in one day
  def self.automatic_start_in_one_day_problem_post(contestproblems)
    if Rails.env.production?
      host = "www.mathraining.be"
    else
      host = "localhost:3000"
    end
    contest = contestproblems[0].contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0
    if contestproblems.size == 1
      plural = false
      mes.content = "Le Problème ##{contestproblems[0].number}"
    else
      plural = true
      mes.content = "Les Problèmes"
      i = 0
      contestproblems.each do |cp|
        if (i == contestproblems.size-1)
          mes.content = mes.content + " et"
        elsif (i > 0)
          mes.content = mes.content + ","
        end
        mes.content = mes.content + " ##{cp.number}"
        i = i+1
      end
    end
    mes.content = mes.content + " du [url=" + Rails.application.routes.url_helpers.contest_url(contest, :host => host) + "]Concours ##{contest.number}[/url] #{plural ? "seront" : "sera"} publié#{plural ? "s" : ""} dans un jour, c'est-à-dire le " + write_date_with_link_forum(contestproblems[0].start_time, contest, contestproblems[0]) + " (heure belge)."
    mes.created_at = contestproblems[0].start_time - 1.day + (contestproblems[0].number).seconds
    mes.save
    if mes.created_at > sub.lastcomment # Security: should always be true
      sub.lastcomment = mes.created_at
      sub.save
    end
    
    sub.following_users.each do |u|
      if !contest.followers.include?(u) # Avoid to send again an email to people already following the contest
        UserMailer.new_followed_message(u.id, sub.id, -1).deliver if Rails.env.production?
      end
    end
  end
  
  # Publish a post on forum to say that solutions to problem can be sent
  def self.automatic_start_problem_post(contestproblems)
    if Rails.env.production?
      host = "www.mathraining.be"
    else
      host = "localhost:3000"
    end
    contest = contestproblems[0].contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0
    if contestproblems.size == 1
      plural = false
      mes.content = "Le [url=" + Rails.application.routes.url_helpers.contestproblem_url(contestproblems[0], :host => host) + "]Problème ##{contestproblems[0].number}[/url]"
    else
      plural = true
      mes.content = "Les Problèmes"
      i = 0
      contestproblems.each do |cp|
        if (i == contestproblems.size-1)
          mes.content = mes.content + " et"
        elsif (i > 0)
          mes.content = mes.content + ","
        end
        mes.content = mes.content + " [url=" + Rails.application.routes.url_helpers.contestproblem_url(cp, :host => host) + "]##{cp.number}[/url]"
        i = i+1
      end
    end
    mes.content = mes.content + " du [url=" + Rails.application.routes.url_helpers.contest_url(contest, :host => host) + "]Concours ##{contest.number}[/url] #{plural ? "sont" : "est"} maintenant accessible#{plural ? "s" : ""}, et les solutions sont acceptées jusqu'au " + write_date_with_link_forum(contestproblems[0].end_time, contest, contestproblems[0]) + " (heure belge)."
    mes.created_at = contestproblems[0].start_time + (contestproblems[0].number).seconds
    mes.save
    if mes.created_at > sub.lastcomment # Security: should always be true
      sub.lastcomment = mes.created_at
      sub.save
    end
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver if Rails.env.production?
    end
  end
end

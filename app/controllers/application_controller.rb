#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_action :has_consent
  before_action :check_takentests
  before_action :check_contests
  #before_action :warning

  ########## PARTIE PRIVEE ##########
  private

  #def warning
  #  flash[:info] = "Le site est en maintenance pour quelques minutes... Merci de votre patience !".html_safe
  #  if !signed_in? || !current_user.root?
  #    redirect_to root_path if request.path != "/"
  #  end
  #end
  
  def has_consent
    $allcolors = Color.order(:pt).to_a
    @ss = signed_in?
    pp = request.fullpath.to_s
    if @ss && current_user.consent.nil? && pp != "/accept_legal" && pp != "/legal" && pp != "/about" && pp != "/contact" && pp != "/signout"
      render 'users/read_legal'
    end
  end

  # Vérifie qu'il ne s'agit pas d'un administrateur dans la peau de quelqu'un
  def notskin_user
    if current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_to(:back)
    end
  end

  # Vérifie qu'on est administrateur
  def admin_user
    if(!current_user.sk.admin)
      flash[:danger] = "Vous n'avez pas accès à cette page."
      redirect_to root_path
    end
  end

  # Vérifie qu'on est root
  def root_user
    if(!current_user.sk.root)
      flash[:danger] = "Vous n'avez pas accès à cette page."
      redirect_to root_path
    end
  end

  # Gérer les pièces jointes
  def create_files
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return [];
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)
      @error = true
      @error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)."
      return [];
    end

    return attach
  end

  def update_files(about)
    totalsize = 0
    about.myfiles.each do |f|
      if params["prevfile#{f.id}".to_sym].nil?
        f.file.destroy
        f.destroy
      else
        totalsize = totalsize + f.file_file_size
      end
    end

    about.fakefiles.each do |f|
      if params["prevfakefile#{f.id}".to_sym].nil?
        f.destroy
      end
    end

    attach = Array.new

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Myfile.new(:file => params["file#{k}".to_sym])
        attach[i-1].myfiletable = about
        if !attach[i-1].save
          destroy_files(attach, i)
          nom = params["file#{k}".to_sym].original_filename
          @error = true
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return []
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 5.megabytes
      destroy_files(attach, i)
      @error = true
      @error_message = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)"
      return []
    end
  end

  def destroy_files(attach, i)
    j = 1
    while j < i do
      attach[j-1].file.destroy
      attach[j-1].destroy
      j = j+1
    end
  end
  
  # Regarde s'il y a un test virtuel qui vient de se terminer
  def check_takentests
    time_now = DateTime.now.to_i
    Takentestcheck.all.each do |c|
      t = c.takentest
      if t.status != 0
        c.destroy # Should not happen in theory
      else
        debut = t.takentime.to_i
        if debut + t.virtualtest.duration*60 < time_now
          c.destroy
          t.status = 1
          t.save
          u = t.user
          v = t.virtualtest
          v.problems.each do |p|
            p.submissions.where(user_id: u.id, intest: true).each do |s|
              s.visible = true
              s.save
            end
          end
        end
      end
    end
  end
  
  def check_contests
    date_now = DateTime.now
    date_in_one_day = 1.day.from_now
    Contestproblemcheck.all.each do |c|
      p = c.contestproblem
      if p.status == 0
        if p.start_time <= date_in_one_day
          p.status = 1
          p.save
          automatic_start_in_one_day_problem_post(p)
          p.contest.followers.each do |u|
            UserMailer.new_followed_contestproblem(u.id, p.id).deliver if Rails.env.production?
          end
        end
      end        
      if p.status == 1
        if p.start_time <= date_now
          p.status = 2
          p.save
          automatic_start_problem_post(p)
        end
      end
      if p.status == 2
        if p.end_time <= date_now
          c.destroy
          p.status = 3
          p.save
        end
      end
      if p.status == 3
        c.destroy # Should not happen in theory
      end
    end
  end
  
  # Publish a post on forum to say that problem will be published in one day
  def automatic_start_in_one_day_problem_post(contestproblem)
    contest = contestproblem.contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0
    mes.content = "Le Problème ##{contestproblem.number} du [url=" + contest_url(contest) + "]Concours ##{contest.number}[/url] sera publié dans un jour, c'est-à-dire le " + write_date_with_link_forum(contestproblem.start_time, contest, contestproblem) + " (heure belge)."
    mes.created_at = contestproblem.start_time - 1.day
    mes.save
    sub.lastcomment = mes.created_at
    sub.save
  end
  
  # Publish a post on forum to say that solutions to problem can be sent
  def automatic_start_problem_post(contestproblem)
    contest = contestproblem.contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0
    mes.content = "Le [url=" + contestproblem_url(contestproblem) + "]Problème ##{contestproblem.number}[/url] du [url=" + contest_url(contest) + "]Concours ##{contest.number}[/url] est maintenant accessible, et les solutions sont acceptées jusqu'au " + write_date_with_link_forum(contestproblem.end_time, contest, contestproblem) + " (heure belge)."
    mes.created_at = contestproblem.start_time
    mes.save
    sub.lastcomment = mes.created_at
    sub.save
  end
  
end

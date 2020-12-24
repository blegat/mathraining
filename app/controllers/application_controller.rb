#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_action :has_consent
  before_action :check_takentests
  #before_action :warning

  ########## PARTIE PRIVEE ##########
  private

  #def warning
  #  flash[:info] = "Le site est en maintenance pour quelques minutes... Merci de votre patience !".html_safe
  #  if !@signed_in || !current_user.root?
  #    redirect_to root_path if request.path != "/"
  #  end
  #end
  
  def has_consent
    $allcolors = Color.order(:pt).to_a
    @signed_in = signed_in?
    pp = request.fullpath.to_s
    if @signed_in && !current_user.last_policy_read && pp != "/accept_legal" && pp != "/last_policy" && !pp.include?("/privacypolicies") && pp != "/about" && pp != "/contact" && pp != "/signout"
      if Privacypolicy.where(:online => true).count > 0 # Si aucune privacy policy alors on ne redirige pas...
        render 'users/read_legal' and return
      end
    end
  end
  
  def signed_in_user
    unless @signed_in
      store_location
      flash[:danger] = "Vous devez être connecté pour accéder à cette page."
      redirect_to signin_path
    end
  end
  
  # Dans le cas d'une page compromettante (du type "rendre quelqu'un administrateur"), on ne permet pas une redirection douteuse
  def signed_in_user_danger
    unless @signed_in
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie qu'on est pas connecté
  def signed_out_user
    if @signed_in
      redirect_to root_path
    end
  end

  # Vérifie qu'il ne s'agit pas d'un administrateur dans la peau de quelqu'un
  def notskin_user
    if @signed_in && current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_to(:back)
    end
  end

  # Vérifie qu'on est administrateur
  def admin_user
    if !@signed_in || !current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end

  # Vérifie qu'on est root
  def root_user
    if !@signed_in || !current_user.sk.root
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie qu'on est correcteur ou admin
  def corrector_user
    if !@signed_in || (!current_user.sk.admin && !current_user.sk.corrector)
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie que l'on a assez de points si on est étudiant
  def enough_points
    if !has_enough_points
      render 'errors/access_refused' and return
    end
  end
  
  def swap_position(a, b)
    x = a.position
    a.position = b.position
    b.position = x
    a.save
    b.save
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
  
  # Check if a contest problem just started or ended (done only when charging a contest related page)
  def check_contests
    date_now = DateTime.now
    # Note: Problems in Contestproblemcheck are also used in contest.rb to check problems for which an email or forum subject must be created
    Contestproblemcheck.all.order(:id).each do |c|
      p = c.contestproblem
      if p.status == 1 # Contest is online but problem is not published yet
        if p.start_time <= date_now
          p.status = 2
          p.save
        end
      end
      if p.status == 2 # Problem has started but not ended
        if p.end_time <= date_now
          p.status = 3
          p.save
        end
      end
      if p.status == 3 and p.reminder_status == 2 # Avoid to delete if reminders were not sent yet
        c.destroy
      end
    end
  end
  
  def compute_new_contest_rankings(contest)
    userset = Set.new
    probs = contest.contestproblems.where("status >= 4")
    probs.each do |p|
      p.contestsolutions.where("score > 0 AND official = ?", false).each do |s|
        userset.add(s.user_id)
      end
    end
    scores = Array.new
    userset.each do |u|
      score = 0
      probs.each do |p|
        sol =  p.contestsolutions.where(:user_id => u).first
        if !sol.nil?
          score = score + sol.score
        end
      end
      scores.push([-score, u])
    end
    scores.sort!
    prevscore = -1
    i = 1
    rank = 0
    scores.each do |a|
      score = -a[0]
      u = a[1]
      if score != prevscore
        rank = i
        prevscore = score
      end
      cs = Contestscore.where(:contest => @contest, :user_id => u).first
      if cs.nil?
        cs = Contestscore.new
        cs.contest = contest
        cs.user_id = u
      end
      cs.rank = rank
      cs.score = score
      cs.save
      i = i+1
    end
  end
  
end

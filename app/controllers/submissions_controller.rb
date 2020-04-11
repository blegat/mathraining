#encoding: utf-8
class SubmissionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :create_intest, :update_brouillon, :update_intest, :read, :unread, :star, :unstar, :reserve, :unreserve, :destroy, :update_score, :uncorrect, :mark_as_plagiarism, :search_script]
  before_action :root_user, only: [:update_score, :uncorrect, :mark_as_plagiarism]
  before_action :get_problem
  before_action :get_submission, only: [:destroy]
  before_action :get_submission2, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :update_brouillon, :update_intest, :update_score, :uncorrect, :mark_as_plagiarism, :search_script]
  before_action :root_user_or_in_test, only: [:destroy]
  before_action :corrector_user_having_access, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :search_script]
  before_action :not_solved, only: [:create]
  before_action :can_submit, only: [:create]
  before_action :has_access, only: [:create]
  before_action :enough_points, only: [:create]
  before_action :in_test, only: [:create_intest, :update_intest]
  before_action :brouillon, only: [:update_brouillon]
  before_action :can_see_submissions, only: [:index]

  # Voir toutes les soumissions à un problème (via javascript uniquement)
  def index
    if @what == 0
      @submissions = @problem.submissions.where('user_id != ? AND status = 2 AND star = ? AND visible = ?', current_user.sk, false, true).order('created_at DESC')
    elsif @what == 1
      @submissions = @problem.submissions.where('user_id != ? AND status != 2 AND visible = ?', current_user.sk, true).order('created_at DESC')
    end

    respond_to do |format|
      format.js
    end
  end

  # Créer une nouvelle soumission
  def create
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      flash[:danger] = @error_message
      session[:ancientexte] = params[:submission][:content]
      redirect_to problem_path(@problem, :sub => 0) and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.lastcomment = DateTime.current

    if params[:commit] == "Enregistrer comme brouillon"
      submission.visible = false
      submission.status = -1
    end

    # Si on réussit à sauver
    if submission.save
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, submission)
        attach[j-1].save
        j = j+1
      end

      if submission.status == -1
        flash[:success] = "Votre brouillon a bien été enregistré."
        redirect_to problem_path(@problem, :sub => 0)
      else
        flash[:success] = "Votre solution a bien été soumise."
        redirect_to problem_path(@problem, :sub => submission.id)
      end

      # Si il y a eu une erreur
    else
      destroy_files(attach, attach.size()+1)
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
      else
        flash[:danger] = "Une erreur est survenue."
      end
      redirect_to problem_path(@problem, :sub => 0)
    end
  end

  # Faire une nouvelle soumission
  def create_intest
    oldsub = @problem.submissions.where(user_id: current_user.sk.id, intest: true).first
    if !oldsub.nil?
      @submission = oldsub
      @context = 1
      update_submission
      return
    end
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      flash[:danger] = @error_message
      session[:ancientexte] = params[:submission][:content]
      redirect_to virtualtest_path(@t, :p => @problem.id) and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.intest = true
    submission.visible = false
    submission.lastcomment = DateTime.current

    if submission.save
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, submission)
        attach[j-1].save
        j = j+1
      end
      flash[:success] = "Votre solution a bien été enregistrée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    else
      destroy_files(attach, attach.size()+1)
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
      else
        flash[:danger] = "Une erreur est survenue."
      end
      redirect_to virtualtest_path(@t, :p => @problem.id)
    end
  end

  # Modifier un brouillon / l'envoyer
  def update_brouillon
    if params[:commit] == "Enregistrer le brouillon"
      @context = 2
      update_submission
    elsif params[:commit] == "Supprimer ce brouillon"
      @submission.myfiles.each do |f|
        f.destroy
      end
      @submission.fakefiles.each do |f|
        f.destroy
      end
      @submission.delete
      flash[:success] = "Brouillon supprimé."
      redirect_to @problem
    else
      @context = 3
      update_submission
    end
  end

  # Modifier une soumission
  def update_intest
    @context = 1
    update_submission
  end

  # Marquer comme lu
  def read
    un_read(true, "lue")
    if @submission.status == 3
      @submission.status = 1
      @submission.save
    end
  end

  # Marquer comme non lu
  def unread
    un_read(false, "non lue")
  end

  # Marquer comme élégant
  def star
    @submission.star = true
    @submission.save
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Marquer comme non élégant
  def unstar
    @submission.star = false
    @submission.save
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Réserver la soumission
  def reserve
    if @submission.followings.count > 0
      if(@submission.followings.first.user == current_user.sk)
        @what = 3
      else
        @correct_name = @submission.followings.first.user.name
        @what = 2
      end
    else
      f = Following.new
      f.user = current_user.sk
      f.submission = @submission
      f.read = true
      f.save
      @what = 3
    end
  end

  # Dé-réserver la soumission
  def unreserve
    f = @submission.followings.first
    if @submission.status != 0 || f.nil? || f.user != current_user.sk
      @what = 0
    else
      Following.delete(f.id)
      @what = 1
    end
  end

  # Supprimer une soumission
  def destroy
    @submission.destroy
    if current_user.sk.admin?
      flash[:success] = "Soumission supprimée."
      redirect_to problem_path(@problem)
    else
      # Etudiant en test
      flash[:success] = "Solution supprimée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    end
  end
  
  # Modifier le score d'une soumission à un test
  def update_score
    if @submission.intest && @submission.score != -1
      @submission.score = params[:new_score].to_i
      @submission.save
    end
    redirect_to problem_path(@problem, :sub => @submission)
  end
  
  # Marquer une soumission correcte comme erronée
  def uncorrect
    u = @submission.user
    if @submission.status == 2
      @submission.status = 1
      @submission.save
      nb_corr = Submission.where(:problem => @problem, :user => u, :status => 2).count
      if nb_corr == 0
        # Si c'était la seule soumission correcte, alors il faut agir et baisser le score
        sp = Solvedproblem.where(:submission => @submission).first
        sp.destroy
        u.rating = u.rating - @problem.value
        u.save
        pps = Pointspersection.where(:user => u, :section_id => @problem.section).first
        pps.points = pps.points - @problem.value
        pps.save
      else
        # Si il y a d'autres soumissions il faut peut-être modifier le submission_id du Solvedproblem correspondant
        sp = Solvedproblem.where(:problem => @problem, :user => u).first
        if sp.submission == @submission
          which = -1
          resolutiontime = nil
          truetime = nil
          Submission.where(:problem => @problem, :user => u, :status => 2).each do |s| 
            lastcomm = s.corrections.where("user_id != ?", u.id).order(:created_at).last
            if(which == -1 || lastcomm.created_at < resolutiontime)
              which = s.id
              resolutiontime = lastcomm.created_at
              usercomm = s.corrections.where("user_id = ? AND created_at < ?", u.id, resolutiontime).last
              if usercomm.nil?
                truetime = s.created_at
              else
                truetime = usercomm.created_at
              end
            end
          end
          sp.submission_id = which
          sp.resolutiontime = resolutiontime
          sp.truetime = truetime
          sp.save
        end
      end
    end
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Marquer la solution comme étant du plagiat
  def mark_as_plagiarism
    @submission.status = 4
    @submission.save
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Chercher une chaine de caractères dans toutes les soumissions
  def search_script
    @problem = @submission.problem
    @string_to_search = params[:string_to_search]
    @enough_caracters = (@string_to_search.size >= 3)

    if @enough_caracters
      search_in_comments = !params[:search_in_comments].nil?

      @all_found = Array.new

      @problem.submissions.where(:visible => true).order("created_at DESC").each do |s|
        pos = s.content.index(@string_to_search)
        if !pos.nil?
          @all_found.push([s, strip_content(s.content, @string_to_search, pos)])
        elsif search_in_comments
          s.corrections.where(:user => s.user).each do |c|
            pos = c.content.index(@string_to_search)
            if !pos.nil?
              @all_found.push([s, strip_content(c.content, @string_to_search, pos)])
            end
          end
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  # Pas déjà résolu
  def not_solved
    redirect_to root_path if current_user.sk.pb_solved?(@problem)
  end

  # Peut envoyer une soumission
  def can_submit
    Submission.where(:user_id => current_user.sk, :problem_id => @problem).each do |s|
      if s.status == 0 or s.status == 4 # Soumission en attente de correction, ou plagiée
        redirect_to problem_path(@problem) and return
      end
    end
  end
  
  def get_submission
    @submission = Submission.find_by_id(params[:id])
    if @submission.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_submission2
    @submission = Submission.find_by_id(params[:submission_id])
    if @submission.nil?
      render 'errors/access_refused' and return
    end
  end

  # Récupère le problème
  def get_problem
    if !params[:problem_id].nil?
      @problem = Problem.find_by_id(params[:problem_id])
      if @problem.nil?
        render 'errors/access_refused' and return
      end
    end
  end

  # Vérifie qu'on peut voir le problème associé
  def has_access
    visible = true
    if !@signed_in || !current_user.sk.admin?
      @problem.chapters.each do |c|
        visible = false if !@signed_in || !current_user.sk.chap_solved?(c)
      end
    end

    t = @problem.virtualtest
    if !t.nil?
      if !@signed_in
        visible = false
      elsif !current_user.sk.admin?
        if current_user.sk.status(t) <= 0
          visible = false
        end
      end
    end

    redirect_to root_path if !visible
  end

  # Est-ce qu'on est en test?
  def in_test
    @t = @problem.virtualtest
    if @t.nil?
      render 'errors/access_refused' and return
    else
      redirect_to virtualtests_path if current_user.sk.status(@t) != 0
    end
  end
  
  def root_user_or_in_test
    @problem = @submission.problem
    if !current_user.sk.root?
      in_test
    end
  end

  # Est-ce qu'on est propriétaire de ce brouillon?
  def brouillon
    unless @submission.user == current_user.sk && @submission.problem == @problem && @submission.status == -1
      redirect_to @problem
    end
  end

  def corrector_user_having_access
    unless current_user.sk.admin or (current_user.sk.corrector && current_user.sk.pb_solved?(@submission.problem) && current_user.sk != @submission.user)
      render 'errors/access_refused' and return
    end
  end
  
  def update_submission
    if @context == 1
      lepath = virtualtest_path(@t, :p => @problem.id) # update in test
    elsif @context == 2
      lepath = problem_path(@problem, :sub => 0)
    else
      lepath = problem_path(@problem, :sub => 0)
    end
    
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    @submission.content = params[:submission][:content]
    if @submission.valid?
      totalsize = 0

      @submission.myfiles.each do |f|
        if params["prevfile#{f.id}".to_sym].nil?
          f.file.destroy
          f.destroy
        else
          totalsize = totalsize + f.file_file_size
        end
      end

      @submission.fakefiles.each do |f|
        if params["prevfakefile#{f.id}".to_sym].nil?
          f.destroy
        end
      end

      @error = false
      @error_message = ""

      update_files(@submission) # Fonction commune pour toutes les pièces jointes

      if @error
        flash[:danger] = @error_message
        session[:ancientexte] = params[:submission][:content]
        redirect_to lepath and return
      end
      
      @submission.save

      if @context == 1
        flash[:success] = "Votre solution a bien été modifiée."
        redirect_to virtualtest_path(@t, :p => @problem.id)
      elsif @context == 2
        flash[:success] = "Votre brouillon a bien été enregistré."
        redirect_to lepath
      else
        @submission.status = 0
        @submission.created_at = DateTime.current
        @submission.lastcomment = @submission.created_at
        @submission.visible = true
        @submission.save
        flash[:success] = "Votre solution a bien été soumise."
        redirect_to problem_path(@problem, :sub => @submission.id)
      end
    else
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
      else
        flash[:danger] = "Une erreur est survenue."
      end
      redirect_to lepath
    end
  end

  # Lu et non lu
  def un_read(read, msg)
    following = Following.where(:user_id => current_user.sk, :submission_id => @submission).first
    if !following.nil?
      following.read = read
      if following.save
        flash[:success] = "Soumission marquée comme #{msg}."
        redirect_to problem_path(@problem, :sub => @submission)
      else
        flash[:danger] = "Un problème est apparu."
        redirect_to problem_path(@problem, :sub => @submission)
      end
    elsif !read
      following = Following.new
      following.user = current_user.sk
      following.submission = @submission
      following.read = read
      if following.save
        flash[:success] = "Soumission marquée comme #{msg}."
        redirect_to problem_path(@problem, :sub => @submission)
      else
        flash[:danger] = "Un problème est apparu."
        redirect_to problem_path(@problem, :sub => @submission)
      end
    else
      redirect_to root_path
    end
  end

  def can_see_submissions
    if !(params.has_key?:what)
      redirect_to root_path
    end
    @what = params[:what].to_i
    if @what == 0    # See correct submissions (need to have solved problem or to be admin)
      if !current_user.sk.admin? and !current_user.sk.pb_solved?(@problem)
        redirect_to root_path
      end
    elsif @what == 1 # See incorrect submissions (need to be admin or corrector)
      if !current_user.sk.admin? and !current_user.sk.corrector?
        redirect_to root_path
      end
    else
      redirect_to root_path
    end
  end

  # Private method used to create a preview of a substring of a string
  def strip_content(content, string_found, pos)
    start1 = [pos - 30, 0].max
    if start1 < 4
      start1 = 0
    end
    stop1 = pos
    start2 = pos + string_found.size
    stop2 = [start2 + 30, content.size].min
    if stop2 > content.size - 4
      stop2 = content.size
    end
    return [(start1 > 0 ? "..." : "") + content[start1, stop1-start1], content[start2, stop2-start2] + (stop2 < content.size ? "..." : "")]
  end
end

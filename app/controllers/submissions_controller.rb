#encoding: utf-8
class SubmissionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :get_problem
  before_filter :can_see, only: [:show]
  before_filter :admin_user, only: [:destroy, :read, :unread, :reserve, :unreserve]
  before_filter :not_solved, only: [:create]
  before_filter :can_submit, only: [:create]
  before_filter :has_access, only: [:create]
  before_filter :enough_points, only: [:create]
  before_filter :in_test, only: [:intest, :create_intest, :update_intest]

  # Montrer une soumission : il faut qu'on puisse la voir
  def show
    if @submission.nil?
      redirect_to root_path
    end
    notif = current_user.sk.notifs.where(submission_id: @submission.id)
    if notif.size > 0 && !current_user.other
      notif.first.delete
    end

    @ancientexte = session[:ancientexte]
    session[:ancientexte] = nil
  end

  # Créer une nouvelle soumission
  def create
    # Pièces jointes
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Submissionfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          session[:ancientexte] = params[:submission][:content]
          redirect_to problem_path(@problem, :sub => 0),
            flash: {danger: "Votre pièce jointe '#{nom}' ne respecte pas les conditions." } and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 10485760
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      redirect_to problem_path(@problem, :sub => 0),
          flash: {danger: "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)" } and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.lastcomment = DateTime.current
    
    # Si on réussit à sauver
    if submission.save
      j = 1
      while j < i do
        attach[j-1].submission = submission
        attach[j-1].save
        j = j+1
      end
      redirect_to problem_path(@problem, :sub => submission.id)
    
    # Si il y a eu une erreur
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
        redirect_to problem_path(@problem, :sub => 0)
      elsif params[:submission][:content].size > 8000
        flash[:danger] = "Votre soumission doit faire moins de 8000 caractères."
        redirect_to problem_path(@problem, :sub => 0)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_path(@problem, :sub => 0)
      end
    end
  end
  
  # Voir une soumission pendant un test
  def intest
    @neworedit = 0
    @submission = @problem.submissions.where(user_id: current_user.sk.id, intest: true).first
    if @submission.nil?
      @neworedit = 0
    else
      @neworedit = 1
    end
    
    @numero = 0
    x = 1
    
    @t.problems.order(:position).each do |p|
      @numero = x if p.id == @problem.id
      x = x+1
    end
  end
  
  # Faire une nouvelle soumission
  def create_intest
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Submissionfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          session[:ancientexte] = params[:submission][:content]
          redirect_to problem_intest_path(@problem),
            flash: {danger: "Votre pièce jointe '#{nom}' ne respecte pas les conditions." } and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 10485760
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      redirect_to problem_intest_path(@problem),
          flash: {danger: "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)" } and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.intest = true
    submission.visible = false
    submission.lastcomment = Datetime.current

    if submission.save
      j = 1
      while j < i do
        attach[j-1].submission = submission
        attach[j-1].save
        j = j+1
      end
      flash[:success] = "Votre solution a bien été enregistrée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
        redirect_to problem_intest_path(@problem)
      elsif params[:submission][:content].size > 8000
        flash[:danger] = "Votre soumission doit faire moins de 8000 caractères."
        redirect_to problem_intest_path(@problem)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_intest_path(@problem)
      end
    end
  end
  
  # Modifier une soumission
  def update_intest
    @submission = Submission.find(params[:submission_id])
    if @submission.update_attributes(params[:submission])
    
      totalsize = 0
      
      @submission.submissionfiles.each do |sf|
        if params["prevfile#{sf.id}".to_sym].nil?
          sf.file.destroy
          sf.destroy
        else
          totalsize = totalsize + sf.file_file_size
        end
      end
      
      @submission.fakesubmissionfiles.each do |sf|
        if params["prevfakefile#{sf.id}".to_sym].nil?
          sf.destroy
        end
      end
      
      attach = Array.new

      i = 1
      k = 1
      while !params["hidden#{k}".to_sym].nil? do
        if !params["file#{k}".to_sym].nil?
          attach.push()
          attach[i-1] = Submissionfile.new(:file => params["file#{k}".to_sym])
          if !attach[i-1].save
            j = 1
            while j < i do
              attach[j-1].file.destroy
              attach[j-1].destroy
              j = j+1
            end
            nom = params["file#{k}".to_sym].original_filename
            session[:ancientexte] = params[:submission][:content]
            redirect_to problem_intest_path(@problem),
              flash: {danger: "Votre pièce jointe '#{nom}' ne respecte pas les conditions." } and return
          end
          totalsize = totalsize + attach[i-1].file_file_size

          i = i+1
        end
        k = k+1
      end

      if totalsize > 10485760
        j = 1
        while j < i do
          attach[j-1].file.destroy
          attach[j-1].destroy
          j = j+1
        end
        session[:ancientexte] = params[:submission][:content]
        redirect_to problem_intest_path(@problem),
            flash: {danger: "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)" } and return
      end
      
      j = 1
      while j < i do
        attach[j-1].submission = @submission
        attach[j-1].save
        j = j+1
      end
      
      flash[:success] = "Votre solution a bien été modifiée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    else
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
        redirect_to problem_intest_path(@problem)
      elsif params[:submission][:content].size > 8000
        flash[:danger] = "Votre soumission doit faire moins de 8000 caractères."
        redirect_to problem_intest_path(@problem)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_intest_path(@problem)
      end
    end    
  end

  # Lu et non lu
  def un_read(read, msg)
    following = Following.find_by_user_id_and_submission_id(current_user.sk, @submission)
    if following
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
  
  # Marquer comme lu
  def read
    @submission = Submission.find(params[:submission_id])
    un_read(true, "lue")
    if @submission.status == 3
      @submission.status = 1
      @submission.save
    end
  end

  # Marquer comme non lu
  def unread
    @submission = Submission.find(params[:submission_id])
    un_read(false, "non lue")
  end
  
  # Réserver la soumission
  def reserve
    @submission = Submission.find(params[:submission_id])
    if @submission.followings.count > 0
      flash[:danger] = "Cette soumission a déjà été réservée."
      redirect_to problem_path(@problem, :sub => @submission)
    else
      f = Following.new
      f.user = current_user.sk
      f.submission = @submission
      f.read = true
      f.save
      flash[:success] = "Soumission réservée."
      redirect_to problem_path(@problem, :sub => @submission)
    end
  end
  
  # Dé-réserver la soumission
  def unreserve
    @submission = Submission.find(params[:submission_id])
    f = @submission.followings.first
    if @submission.status != 0 || f.nil? || f.user != current_user.sk
      redirect_to problem_path(@problem, :sub => @submission)
    else
      Following.delete(f.id)
      flash[:success] = "Réservation annulée."
      redirect_to problem_path(@problem, :sub => @submission)
    end
  end
  
  def destroy
    @submission = Submission.find(params[:id])
    @problem = @submission.problem
    @submission.corrections.each do |c|
      c.destroy
    end
    @submission.destroy
    redirect_to problem_path(@problem)
  end
  
  ########## PARTIE PRIVEE ##########
  private

  # Peut voir la soumission
  def can_see
    @submission = Submission.find_by_id(params[:id])
    if ((@submission.problem != @problem) || (@submission.user != current_user.sk && !current_user.sk.solved?(@problem) && !current_user.sk.admin))
      redirect_to root_path
    end
  end

  # Pas déjà résolu
  def not_solved
    redirect_to root_path if current_user.sk.solved?(@problem)
  end
  
  # Peut envoyer une soumission
  def can_submit
    lastsub = Submission.where(:user_id => current_user.sk, :problem_id => @problem).order('created_at')
    redirect_to problem_path(@problem) if (!lastsub.empty? && lastsub.last.status == 0)
  end

  # Récupère le problème
  def get_problem
    if !params[:problem_id].nil?
      @problem = Problem.find(params[:problem_id])
    end
  end
  
  # Vérifie qu'on peut voir le problème associé
  def has_access
    visible = true
    if !signed_in? || !current_user.sk.admin?
      @problem.chapters.each do |c|
        visible = false if !signed_in? || !current_user.sk.solved?(c)
      end
    end
    
    t = @problem.virtualtest
    if !t.nil?
      if !signed_in?
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
      redirect_to root_path
    else
      redirect_to @t if current_user.sk.status(@t) != 0
    end
  end
  
  # Attribution des points pour un problème
  def point_attribution(user, problem)
    if !user.solved?(problem) # Avoid double count
      pt = problem.value

      partials = user.pointspersections

      if !problem.section.fondation? # Pas un fondement
        user.point.rating = user.point.rating + pt
        user.point.save
      end

      partial = partials.where(:section_id => problem.section.id).first
      partial.points = partial.points + pt
      partial.save
    end
  end
  
  # Vérifie que l'on a assez de points si on est étudiant
  def enough_points
    if !current_user.sk.admin?
      score = current_user.sk.point.rating
      redirect_to root_path if score < 200
    end
  end
end

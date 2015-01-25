#encoding: utf-8
class CorrectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :correct_user

  # Créer une correction : il faut être soit admin, soit l'étudiant de la soumission
  def create
    attach = Array.new
    totalsize = 0
    
    # Si il faut donner un score, on vérifie que le score est donné
    if @submission.status == 0 && @submission.intest && @submission.score == -1 && (params["score".to_sym].nil? || params["score".to_sym].blank?)
      flash[:danger] = "Veuillez donner un score à cette solution."
      session[:ancientexte] = params[:correction][:content]
      redirect_to problem_path(@submission.problem, :sub => @submission) and return
    end
    
    # On vérifie qu'il n'y a pas eu de nouveau message entre
    lastid = -1
    @submission.corrections.order(:created_at).each do |correction|
      lastid = correction.id
    end
    
    if lastid != params[:lastcomment].to_i
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = "Un nouveau commentaire a été posté avant le vôtre! Veuillez en prendre connaissance et reposter votre commentaire si nécessaire."
      redirect_to problem_path(@submission.problem, :sub => @submission) and return
    end
    
    # On parcourt toutes les pièces jointes
    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Correctionfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          session[:ancientexte] = params[:correction][:content]
          flash[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          redirect_to problem_path(@submission.problem, :sub => @submission) and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end
    
    # On vérifie la taille des pièces jointes
    if totalsize > 10485760
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)."
      redirect_to problem_path(@submission.problem, :sub => @submission) and return
    end

    correction = @submission.corrections.build(params[:correction])
    correction.user = current_user.sk
    
    # Si la sauvegarde se passe bien
    if correction.save
      # On enregistre les pièces jointes
      j = 1
      while j < i do
        attach[j-1].correction = correction
        attach[j-1].save
        j = j+1
      end
      
      # On attribue le score s'il faut
      if @submission.status == 0 && @submission.intest && @submission.score == -1
        @submission.score = params["score".to_sym].to_i
      end
      
      # On supprime les réservations s'il faut
      if @submission.status == 0 && current_user.sk.admin?
        @submission.followings.each do |f|
          Following.delete(f.id)
        end
      end

      # On change le statut de la soumission
      # Il ne change pas s'il vaut 2 (déjà résolu)
      
      # Si erroné et étudiant : nouveau commentaire
      if current_user.sk == @submission.user and @submission.status == 1
        @submission.status = 3
        @submission.save
        m = ''
      
      # Si admin et nouvelle soumission : cela dépend du bouton
      elsif current_user.sk.admin and (@submission.status == 0 or @submission.status == 3) and
        (params[:commit] == "Poster et refuser la soumission" or
         params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'
        
      # Si soumission erronée et on accepte : devient correcte
      elsif current_user.sk.admin and params[:commit] == "Poster et accepter la soumission"
        @submission.status = 2
        @submission.save
        
        # On donne les points et on enregistre qu'il est résolu
        unless @submission.user.solved?(@submission.problem)
          point_attribution(@submission.user, @submission.problem)
          link = Solvedproblem.new
          link.user_id = @submission.user.id
          link.problem_id = @submission.problem.id
          link.resolutiontime = DateTime.now
          link.save
        end
        m = ' et soumission marquée comme correcte'
        
      # Sinon : on fait juste savoir qu'on a fait quelque chose
      else
        @submission.touch
      end
      
      # On gère les notifications
      if current_user.sk.admin?
        following = Following.find_by_user_id_and_submission_id(current_user.sk, @submission)
        if following.nil?
          following = Following.new
          following.user = current_user.sk
          following.submission = @submission
        end
        following.read = true
        following.save

        @submission.followings.each do |f|
          if f.user == current_user.sk
            f.touch
          else
            f.read = false
            f.save
          end
        end

        notif = Notif.new
        notif.user = @submission.user
        notif.submission = @submission
        notif.save
      elsif current_user.sk == @submission.user
        # An else would have the same effect normally
        @submission.followings.update_all(read: false)
      end
      
      flash[:success] = "Réponse postée#{m}."
      redirect_to problem_path(@submission.problem, :sub => @submission)
      
    # Si il y a eu une erreur au moment de sauver
    else
      # On supprime les pièces jointes
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:correction][:content]
      if params[:correction][:content].size == 0
        flash[:danger] = "Votre réponse est vide."
        redirect_to problem_path(@submission.problem, :sub => @submission)
      elsif params[:correction][:content].size > 8000
        flash[:danger] = "Votre réponse doit faire moins de 8000 caractères."
        redirect_to problem_path(@submission.problem, :sub => @submission)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_path(@submission.problem, :sub => @submission)
      end
    end
  end
  
  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'il s'agit du bon utilisateur ou d'un admin
  def correct_user
    @submission = Submission.find_by_id(params[:submission_id])
    if @submission.nil? || (@submission.user != current_user.sk && !current_user.sk.admin)
      redirect_to root_path
    end
  end
  
  # Attribution des points d'un problème
  def point_attribution(user, problem)
    if !user.solved?(problem) # Eviter les doubles comptages
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
end

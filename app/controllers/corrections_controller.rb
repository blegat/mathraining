#encoding: utf-8
class CorrectionsController < ApplicationController
  before_action :signed_in_user
  before_action :correct_user
  before_action :notskin_user, only: [:create]

  # Créer une correction : il faut être soit admin, soit correcteur, soit l'étudiant de la soumission
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

    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      flash.now[:danger] = @error_message
      session[:ancientexte] = params[:correction][:content]
      redirect_to problem_path(@submission.problem, :sub => @submission) and return
    end

    correction = @submission.corrections.build(params.require(:correction).permit(:content))
    correction.user = current_user.sk

    # Si la sauvegarde se passe bien
    if correction.save
      # On enregistre les pièces jointes
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, correction)
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
      elsif (current_user.sk != @submission.user) and (@submission.status == 0 or @submission.status == 3) and
        (params[:commit] == "Poster et refuser la soumission" or
        params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'

        # Si soumission erronée et on accepte : devient correcte
      elsif (current_user.sk != @submission.user) and params[:commit] == "Poster et accepter la soumission"
        @submission.status = 2
        @submission.save

        # On donne les points et on enregistre qu'il est résolu
        unless @submission.user.pb_solved?(@submission.problem)
          point_attribution(@submission.user, @submission.problem)
          link = Solvedproblem.new
          link.user_id = @submission.user.id
          link.problem_id = @submission.problem.id
          link.resolutiontime = DateTime.now
          link.submission_id = @submission.id

          link.truetime = @submission.created_at
          @submission.corrections.order(:created_at).each do |c|
            if c.user_id == @submission.user_id
              link.truetime = c.created_at
            end
          end

          link.save
        end
        m = ' et soumission marquée comme correcte'

        # On supprime les brouillons!
        pb = @submission.problem
        brouillon = pb.submissions.where('user_id = ? AND status = -1', @submission.user).first
        if !brouillon.nil?
          brouillon.myfiles.each do |f|
            f.destroy
          end
          brouillon.fakefiles.each do |f|
            f.destroy
          end
          brouillon.destroy
        end
      end

      # On gère les notifications
      if current_user.sk != @submission.user
        following = Following.where(:user_id => current_user.sk.id, :submission_id => @submission.id).first
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
      else
        @submission.followings.update_all(read: false)
      end

      # On change la valeur de lastcomment
      @submission.lastcomment = correction.created_at
      @submission.save

      flash[:success] = "Réponse postée#{m}."
      redirect_to problem_path(@submission.problem, :sub => @submission)

      # Si il y a eu une erreur au moment de sauver
    else
      destroy_files(attach, attach.size()+1)
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

  # Vérifie qu'il s'agit du bon utilisateur ou d'un admin ou d'un correcteur
  def correct_user
    @submission = Submission.find(params[:submission_id])
    if @submission.nil? || (@submission.user != current_user.sk && !current_user.sk.admin && (!current_user.sk.corrector || !current_user.sk.pb_solved?(@submission.problem)))
      redirect_to root_path
    end
  end

  # Attribution des points d'un problème
  def point_attribution(user, problem)
    if !user.pb_solved?(problem) # Eviter les doubles comptages
      pt = problem.value

      partials = user.pointspersections

      user.rating = user.rating + pt
      user.save

      partial = partials.where(:section_id => problem.section.id).first
      partial.points = partial.points + pt
      partial.save
    end
  end
end

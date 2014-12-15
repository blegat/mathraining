#encoding: utf-8
class CorrectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :correct_user

  def create
    attach = Array.new
    totalsize = 0
    
    r = 0
    if(params.has_key?:r)
      r = params[:r].to_i
    end
    
    lastid = -1
    
    @submission.corrections.order(:created_at).each do |correction|
      lastid = correction.id
    end
    
    if lastid != params[:lastcomment].to_i
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = "Un nouveau commentaire a été posté avant le vôtre! Veuillez en prendre connaissance et reposter votre commentaire si nécessaire."
      redirect_to problem_path(@submission.problem, :sub => @submission, :r => r) and return
    end

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
          redirect_to problem_path(@submission.problem, :sub => @submission, :r => r) and return
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
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)."
      redirect_to problem_path(@submission.problem, :sub => @submission, :r => r) and return
    end

    correction = @submission.corrections.build(params[:correction])
    correction.user = current_user.sk

    if correction.save
      j = 1
      while j < i do
        attach[j-1].correction = correction
        attach[j-1].save
        j = j+1
      end


      # Change the status of the submission
      # We don't change the status if it is 2 (solved)
      if current_user.sk == @submission.user and @submission.status == 1
        @submission.status = 3
        @submission.save
        m = ''
      elsif current_user.sk.admin and (@submission.status == 0 or @submission.status == 3) and
        (params[:commit] == "Poster et refuser la soumission" or
         params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'
      elsif current_user.sk.admin and params[:commit] == "Poster et accepter la soumission"
        @submission.status = 2
        @submission.save
        unless @submission.user.solved?(@submission.problem)
          point_attribution(@submission.user, @submission.problem)
          link = Solvedproblem.new
          link.user_id = @submission.user.id
          link.problem_id = @submission.problem.id
          link.resolutiontime = DateTime.now
          link.save
        end
        m = ' et soumission marquée comme correcte'
      else
        @submission.touch
      end
      # Put in admin / following
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
          f.touch
        end

        notif = Notif.new
        notif.user = @submission.user
        notif.submission = @submission
        notif.save
      elsif current_user.sk == @submission.user
        # An else would have the same effect normally
        @submission.followings.update_all(read: false)
      end
      # Redirect to the submission
      flash[:success] = "Réponse postée#{m}."
      redirect_to problem_path(@submission.problem, :sub => @submission, :r => r)
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:correction][:content]
      if params[:correction][:content].size == 0
        flash[:danger] = "Votre réponse est vide."
        redirect_to problem_path(@submission.problem, :sub => @submission, :r => r)
      elsif params[:correction][:content].size > 8000
        flash[:danger] = "Votre réponse doit faire moins de 8000 caractères."
        redirect_to problem_path(@submission.problem, :sub => @submission, :r => r)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_path(@submission.problem, :sub => @submission, :r => r)
      end
    end
  end

  private

  def correct_user
    @submission = Submission.find_by_id(params[:submission_id])
    if @submission.nil? or (@submission.user != current_user.sk and not current_user.sk.admin)
      redirect_to root_path
    end
  end

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
end

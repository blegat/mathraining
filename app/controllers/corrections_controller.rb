#encoding: utf-8
class CorrectionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :correct_user

  def create
    correction = @submission.corrections.build(params[:correction])
    correction.user = current_user
    if correction.save
      # Change the status of the submission
      # We don't change the status if it is 2 (solved)
      if current_user == @submission.user and @submission.status == 1
        @submission.status = 3
        @submission.save
        m = ''
      elsif current_user.admin and (@submission.status == 0 or @submission.status == 3) and
        (params[:commit] == "Poster et refuser la soumission" or
         params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'
      elsif current_user.admin and params[:commit] == "Poster et accepter la soumission"
        @submission.status = 2
        @submission.save
        unless @submission.user.solved?(@submission.problem)
          point_attribution(@submission.user, @submission.problem)
          @submission.problem.users << @submission.user
        end
        m = ' et soumission marquée comme correcte'
      else
        @submission.touch
      end
      # Put in admin / following
      if current_user.admin?
        following = Following.find_by_user_id_and_submission_id(current_user, @submission)
        if following.nil?
          following = Following.new
          following.user = current_user
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
      elsif current_user == @submission.user
        # An else would have the same effect normally
        @submission.followings.update_all(read: false)
      end
      # Redirect to the submission
      redirect_to problem_submission_path(@submission.problem, @submission),
        flash: { success: "Réponse postée#{m}" }
    else
      if params[:correction][:content].size == 0
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Votre réponse est vide.' }
      elsif params[:correction][:content].size > 8000
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Votre réponse doit faire moins de 8000 caractères.' }
      else
        redirect_to problem_submission_path(@submission.problem, @submission),
          flash: { error: 'Une erreur est survenue.' }
      end
    end
  end

  private

  def correct_user
    @submission = Submission.find_by_id(params[:submission_id])
    if @submission.nil? or (@submission.user != current_user and not current_user.admin)
      redirect_to root_path
    end
  end

  def point_attribution(user, problem)
    if !user.solved?(problem) # Avoid double count
      pt = 25*problem.level

      partials = user.pointspersections

      if !problem.chapter.sections.empty? # Pas un fondement
        user.point.rating = user.point.rating + pt
        user.point.save
      else # Fondement
        partial = partials.where(:section_id => 0).first
        partial.points = partial.points + pt
        partial.save
      end

      problem.chapter.sections.each do |s| # Section s
        partial = partials.where(:section_id => s.id).first
        partial.points = partial.points + pt
        partial.save
      end
    end
  end
end

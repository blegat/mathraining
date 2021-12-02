#encoding: utf-8
class CorrectionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create]
  
  before_action :get_submission, only: [:create]
  
  before_action :correct_user, only: [:create]
  before_action :not_plagiarized, only: [:create]
  before_action :notskin_user, only: [:create]

  # Create a correction (send the form)
  def create
    params[:correction][:content].strip! if !params[:correction][:content].nil?
    attach = Array.new
    totalsize = 0

    # If a score is needed, we check that the score is set
    if @submission.status == 0 && @submission.intest && @submission.score == -1 && (params["score".to_sym].nil? || params["score".to_sym].blank?)
      flash[:danger] = "Veuillez donner un score à cette solution."
      session[:ancientexte] = params[:correction][:content]
      redirect_to problem_path(@problem, :sub => @submission) and return
    end

    # We check that no new message was posted
    lastid = -1
    @submission.corrections.order(:created_at).each do |correction|
      lastid = correction.id
    end

    if lastid != params[:last_comment_id].to_i
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = "Un nouveau commentaire a été posté avant le vôtre ! Veuillez en prendre connaissance et reposter votre commentaire si nécessaire."
      redirect_to problem_path(@problem, :sub => @submission) and return
    end

    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      flash[:danger] = @error_message
      session[:ancientexte] = params[:correction][:content]
      redirect_to problem_path(@problem, :sub => @submission) and return
    end

    correction = @submission.corrections.build(params.require(:correction).permit(:content))
    correction.user = current_user.sk

    if correction.save
      attach_files(attach, correction)

      # Give the score to the submission
      if @submission.status == 0 && @submission.intest && @submission.score == -1
        @submission.score = params["score".to_sym].to_i
      end

      # Delete reservations if needed
      if @submission.status == 0 && current_user.sk != @submission.user
        @submission.followings.each do |f|
          Following.delete(f.id)
        end
      end

      # Now we change the status of the submission
      # It does not change if it is already equal to 2 (correct)

      # If wrong and current user is the student: new status is 3 (new comment)
      if current_user.sk == @submission.user and @submission.status == 1
        @submission.status = 3
        @submission.save
        m = ''

      # If new/wrong, current user is corrector and he wants to keep it wrong: new status is 1 (wrong)
      elsif (current_user.sk != @submission.user) and (@submission.status == 0 or @submission.status == 3) and
        (params[:commit] == "Poster et refuser la soumission" or
        params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = 1
        @submission.save
        m = ' et soumission marquée comme incorrecte'

      # If current user is corrector and he wants to accept it: new status is 2 (correct)
      elsif (current_user.sk != @submission.user) and params[:commit] == "Poster et accepter la soumission"
        @submission.status = 2
        @submission.save

        # If this is the first correct submission of the user to this problem, we give the points and mark problem as solved
        unless @submission.user.pb_solved?(@problem)
          point_attribution(@submission.user, @problem)
          link = Solvedproblem.new
          link.user_id = @submission.user.id
          link.problem_id = @problem.id
          link.correction_time = DateTime.now
          link.submission_id = @submission.id

          last_user_corr = @submission.corrections.where("user_id = ?", @submission.user_id).order(:created_at).last
          resolution_time = (last_user_corr.nil? ? @submission.created_at : last_user_corr.created_at)
          link.resolution_time = resolution_time
          link.save
          
          # Update the statistics of the problem
          @problem.nb_solves = @problem.nb_solves + 1
          if @problem.first_solve_time.nil? or @problem.first_solve_time > resolution_time
            @problem.first_solve_time = resolution_time
          end
          if @problem.last_solve_time.nil? or @problem.last_solve_time < resolution_time
            @problem.last_solve_time = resolution_time
          end
          @problem.save
        end
        m = ' et soumission marquée comme correcte'

        # Delete the drafts of the user to the problem
        draft = @problem.submissions.where('user_id = ? AND status = -1', @submission.user).first
        if !draft.nil?
          draft.destroy
        end
      end

      # Deal with notifications
      if current_user.sk != @submission.user
        following = Following.where(:user_id => current_user.sk.id, :submission_id => @submission.id).first
        if following.nil?
          following = Following.new
          following.user = current_user.sk
          following.submission = @submission
          if @submission.followings.where("user_id != ?", current_user.sk.id).count > 0
            following.kind = 2 # New corrector for this submission (there was already another one)
          else
            following.kind = 1 # First corrector of the submission
          end
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

      # Change the value of last_comment_time
      @submission.last_comment_time = correction.created_at
      @submission.save

      flash[:success] = "Réponse postée#{m}."
      redirect_to problem_path(@problem, :sub => @submission)

    else # If there is an error when saving
      destroy_files(attach)
      session[:ancientexte] = params[:correction][:content]
      flash[:danger] = error_list_for(correction)
      redirect_to problem_path(@problem, :sub => @submission)
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the submission
  def get_submission
    @submission = Submission.find_by_id(params[:submission_id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
  ########## CHECK METHODS ##########

  # Check that current user is the submission user, or an admin or a corrector having access to the problem
  def correct_user
    if @submission.user != current_user.sk && !current_user.sk.admin && (!current_user.sk.corrector || !current_user.sk.pb_solved?(@problem))
      render 'errors/access_refused' and return
    end
  end

  # Check that the student does not have a plagiarized submission to this problem
  def not_plagiarized
    if Submission.where(:user_id => @submission.user, :problem_id => @problem, :status => 4).count > 0
      render 'errors/access_refused' and return
    end
  end
  
  ########## GET METHODS ##########

  # Helper method to give the points of a problem to a user
  def point_attribution(user, problem)
    if !user.pb_solved?(problem) # Avoid giving two times the points to a same problem
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

#encoding: utf-8
class CorrectionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create]
  
  before_action :get_submission, only: [:create]
  
  before_action :correct_user, only: [:create]
  before_action :no_recent_plagiarism, only: [:create]
  before_action :notskin_user, only: [:create]

  # Create a correction (send the form)
  def create
    params[:correction][:content].strip! if !params[:correction][:content].nil?
    attach = Array.new
    totalsize = 0

    # If a score is needed, we check that the score is set
    if @submission.waiting? && @submission.intest && @submission.score == -1 && (params["score".to_sym].nil? || params["score".to_sym].blank?)
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
      if @submission.waiting? && @submission.intest && @submission.score == -1
        @submission.score = params["score".to_sym].to_i
      end

      # Delete reservations if needed
      if @submission.waiting? && current_user.sk != @submission.user
        @submission.followings.each do |f|
          Following.delete(f.id)
        end
      end

      # Now we change the status of the submission
      # It does not change if it is already correct

      # If wrong and current user is the student: new status is wrong_to_read
      if current_user.sk == @submission.user and @submission.wrong?
        @submission.status = :wrong_to_read
        @submission.save
        m = ''

      # If new/wrong, current user is corrector and he wants to keep it wrong: new status is wrong
      elsif (current_user.sk != @submission.user) and (@submission.waiting? or @submission.wrong_to_read?) and
        (params[:commit] == "Poster et refuser la soumission" or
        params[:commit] == "Poster et laisser la soumission comme erronée")
        @submission.status = :wrong
        @submission.save
        m = ' et soumission marquée comme incorrecte'

      # If current user is corrector and he wants to accept it: new status is correct
      elsif (current_user.sk != @submission.user) and params[:commit] == "Poster et accepter la soumission"
        @submission.status = :correct
        @submission.save

        # If this is the first correct submission of the user to this problem, we give the points and mark problem as solved
        unless @submission.user.pb_solved?(@problem)
          point_attribution(@submission.user, @problem)
          last_user_corr = @submission.corrections.where("user_id = ?", @submission.user_id).order(:created_at).last
          resolution_time = (last_user_corr.nil? ? @submission.created_at : last_user_corr.created_at)
          Solvedproblem.create(:user            => @submission.user,
                               :problem         => @problem,
                               :correction_time => DateTime.now,
                               :submission      => @submission,
                               :resolution_time => resolution_time)
          
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
        draft = @problem.submissions.where(:user => @submission.user, :status => :draft).first
        if !draft.nil?
          draft.destroy
        end
      end

      # Deal with notifications
      if current_user.sk != @submission.user
        need_correction_level_update = false
        following = Following.where(:user => current_user.sk, :submission => @submission).first
        if following.nil?
          following = Following.new(:user => current_user.sk, :submission => @submission)
          if @submission.followings.where("user_id != ?", current_user.sk.id).count > 0
            following.kind = 2 # New corrector for this submission (there was already another one)
          else
            following.kind = 1 # First corrector of the submission
          end
          need_correction_level_update = true
        end
        following.read = true
        following.save
        
        if need_correction_level_update
          current_user.sk.update_correction_level
        end

        @submission.followings.each do |f|
          if f.user == current_user.sk
            f.touch
          else
            f.update_attribute(:read, false)
          end
        end

        Notif.create(:user => @submission.user, :submission => @submission) # (will not be created if already exists)
      else
        @submission.followings.update_all(:read => false)
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
  
  # Check that the student has no (recent) plagiarized solution to the problem
  def no_recent_plagiarism
    if @submission.user == current_user.sk
      s = current_user.sk.submissions.where(:problem => @problem, :status => :plagiarized).order(:last_comment_time).last
      if !s.nil? && s.last_comment_time.to_date + 6.months > Date.today
        redirect_to problem_path(@problem, :sub => @submission) and return
      end
    end
  end
  
  ########## HELPER METHODS ##########

  # Helper method to give the points of a problem to a user
  def point_attribution(user, problem)
    if !user.pb_solved?(problem) # Avoid giving two times the points to a same problem
      pt = problem.value

      partials = user.pointspersections

      user.update_attribute(:rating, user.rating + pt)

      partial = partials.where(:section_id => problem.section.id).first
      partial.update_attribute(:points, partial.points + pt)
    end
  end
end

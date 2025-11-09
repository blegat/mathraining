#encoding: utf-8
class CorrectionsController < ApplicationController
  include SubmissionConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create]
  before_action :user_not_in_skin, only: [:create]
  
  before_action :get_submission, only: [:create]
  
  before_action :user_can_comment_submission, only: [:create]
  before_action :submission_not_draft, only: [:create]
  before_action :submission_not_plagiarized_or_closed, only: [:create]
  before_action :user_has_no_recent_plagiarism_or_closure, only: [:create]
  before_action :submission_not_waiting_in_test, only: [:create]
  before_action :submission_has_recent_activity, only: [:create]

  # Create a correction (send the form)
  def create
    params[:correction][:content].strip! if !params[:correction][:content].nil?
    attach = Array.new
    totalsize = 0
    
    @correction = @submission.corrections.build(params.require(:correction).permit(:content))
    @correction.user = current_user
    
    # Invalid CSRF token
    render_with_error('problems/show', @correction, get_csrf_error_message) and return if @invalid_csrf_token

    # If a score is needed, we check that the score is set and appropriate
    if @submission.waiting? && @submission.intest && @submission.score == -1
      if (params[:score].nil? || params[:score].blank?)
        render_with_error('problems/show', @correction, "Veuillez donner un score à cette solution.") and return
      elsif (params[:score].to_i != 6 && params[:score].to_i != 7 && params[:commit] == "Poster et accepter la soumission")
        render_with_error('problems/show', @correction, "Vous ne pouvez pas accepter une solution sans lui donner un score de 6 ou 7.") and return
      end
    end

    # We check that no new message was posted
    lastid = -1
    @submission.corrections.order(:created_at).each do |c|
      lastid = c.id
    end

    # New comment meanwhile
    if lastid != params[:last_comment_id].to_i
      render_with_error('problems/show', @correction, "Un nouveau commentaire a été posté avant le vôtre ! Veuillez en prendre connaissance et reposter votre commentaire si nécessaire.") and return
    end
    
    # Invalid correction
    render_with_error('problems/show') and return if !@correction.valid?

    # Attached files
    attach = create_files
    render_with_error('problems/show', @correction, @file_error) and return if !@file_error.nil?
    
    @correction.save
    
    attach_files(attach, @correction)

    # Give the score to the submission
    if @submission.waiting? && @submission.intest && @submission.score == -1
      @submission.update_attribute(:score, params[:score].to_i)
    end

    # Delete reservations if needed
    if @submission.waiting? && current_user != @submission.user
      @submission.followings.each do |f|
        Following.delete(f.id)
      end
    end

    # Now we change the status of the submission
    # It does not change if it is already correct
    m = "Votre commentaire a bien été posté."

    # If wrong and current user is the student: new status is wrong_to_read
    if current_user == @submission.user && @submission.wrong?
      @submission.wrong_to_read!

    # If new/wrong, current user is corrector and he wants to keep it wrong: new status is wrong
    elsif (current_user != @submission.user) && (@submission.waiting? || @submission.wrong_to_read?) &&
          params[:commit] == "Poster et refuser la soumission"
          @submission.wrong!
      m = "Soumission marquée comme incorrecte."

    # If current user is corrector and he wants to close it: new status is closed
    elsif (current_user != @submission.user) && (@submission.waiting? || @submission.wrong? || @submission.wrong_to_read?) &&
          params[:commit] == "Poster et clôturer la soumission"
      @submission.closed!
      m = "Soumission clôturée."

    # If current user is corrector and he wants to accept it: new status is correct
    elsif (current_user != @submission.user) && params[:commit] == "Poster et accepter la soumission"
      @submission.mark_correct
      m = "Soumission marquée comme correcte."
    end

    # Deal with notifications
    if current_user != @submission.user
      need_correction_level_update = false
      following = Following.where(:user => current_user, :submission => @submission).first
      if following.nil?
        following = Following.new(:user => current_user, :submission => @submission)
        if @submission.followings.where("user_id != ?", current_user.id).count > 0
          following.kind = :other_corrector
        else
          following.kind = :first_corrector
        end
        need_correction_level_update = true
      end
      following.read = true
      following.save
      
      if need_correction_level_update
        current_user.update_correction_level
      end

      @submission.followings.each do |f|
        if f.user == current_user
          f.touch
        else
          f.update_attribute(:read, false)
        end
      end

      @submission.notified_users << @submission.user unless @submission.notified_users.exists?(@submission.user_id)
    else
      @submission.followings.where.not(:kind => :reservation).update_all(:read => false)
    end
    
    # Deal with saved replied that have been used
    if current_user != @submission.user
      if !params[:correction][:savedreplies_used].nil?
        params[:correction][:savedreplies_used].split(",").each do |id|
          savedreply = Savedreply.find_by_id(id)
          savedreply.update_attribute(:nb_uses, savedreply.nb_uses + 1) if !savedreply.nil?
        end
      end
    end

    flash[:success] = m
    redirect_to problem_path(@problem, :sub => @submission)
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
  def user_can_comment_submission
    if @submission.user != current_user && !current_user.admin? && (!current_user.corrector? || !current_user.pb_solved?(@problem))
      render 'errors/access_refused'
    end
  end  
  
  # Check that the submission is not a draft (i.e. also not a draft in test)
  def submission_not_draft
    if @submission.draft?
      render 'errors/access_refused'
    end
  end
  
  # Check that the submission is not plagiarized or closed (nobody can comment in that case)
  def submission_not_plagiarized_or_closed
    if @submission.plagiarized? || @submission.closed?
      flash[:danger] = "Cette solution ne peut plus être commentée."
      redirect_to problem_path(@problem, :sub => @submission)
    end
  end
  
  # Check that the student does not try to comment a waiting submission from a test
  def submission_not_waiting_in_test
    if @submission.user == current_user && @submission.intest && (@submission.waiting? || @submission.waiting_forever?)
      render 'errors/access_refused'
    end
  end
  
  # Check that submission has recent activity
  def submission_has_recent_activity
    if @submission.user == current_user && @submission.wrong? && !@submission.has_recent_activity
      flash[:danger] = "Cette soumission ne peut plus être commentée."
      redirect_to problem_path(@problem, :sub => @submission)
    end
  end
end

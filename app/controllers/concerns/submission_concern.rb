#encoding: utf-8

module SubmissionConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user is a corrector (or admin) that can correct @submission
  def user_can_correct_submission
    unless signed_in? && @submission.can_be_corrected_by(current_user)
      render 'errors/access_refused'
    end
  end
  
  # Check that the student has no (recent) plagiarized or closed solution to the problem
  def user_has_no_recent_plagiarism_or_closure
    if @submission.nil? || @submission.user == current_user
      if current_user.has_sanction_of_type(:no_submission)
        flash[:danger] = "Action impossible en raison de votre sanction actuelle."
        redirect_to problem_submission_path(@problem, @submission) and return
      end
      s = current_user.submissions.where(:problem => @problem, :status => :plagiarized).order(:last_comment_time).last
      if !s.nil? && s.date_new_submission_allowed > Date.today
        flash[:danger] = "Action impossible en raison d'une solution plagiée sur ce problème."
        redirect_to problem_submission_path(@problem, @submission) and return
      end
      s = current_user.submissions.where(:problem => @problem, :status => :closed).order(:last_comment_time).last
      if !s.nil? && s.date_new_submission_allowed > Date.today
        flash[:danger] = "Action impossible en raison d'une solution clôturée sur ce problème."
        redirect_to problem_submission_path(@problem, @submission) and return
      end
    end
  end
end

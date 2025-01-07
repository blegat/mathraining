#encoding: utf-8

module SubmissionConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user is a corrector (or admin) that can correct @submission
  def user_can_correct_submission
    unless signed_in? && (current_user.admin || (current_user.corrector && current_user.pb_solved?(@problem) && current_user != @submission.user))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the student has no (recent) plagiarized or closed solution to the problem
  def user_has_no_recent_plagiarism_or_closure
    if @submission.nil? || @submission.user == current_user
      if current_user.has_no_submission_sanction
        redirect_to problem_path(@problem, :sub => @submission) and return
      end
      s = current_user.submissions.where(:problem => @problem, :status => :plagiarized).order(:last_comment_time).last
      if !s.nil? && s.date_new_submission_allowed > Date.today
        redirect_to problem_path(@problem, :sub => @submission) and return
      end
      s = current_user.submissions.where(:problem => @problem, :status => :closed).order(:last_comment_time).last
      if !s.nil? && s.date_new_submission_allowed > Date.today
        redirect_to problem_path(@problem, :sub => @submission) and return
      end
    end
  end
end

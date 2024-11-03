#encoding: utf-8

module SubmissionConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user is a corrector (or admin) that can correct @submission
  def user_that_can_correct_submission
    unless signed_in? && (current_user.admin || (current_user.corrector && current_user.pb_solved?(@problem) && current_user != @submission.user))
      render 'errors/access_refused' and return
    end
  end
end

#encoding: utf-8

module ProblemConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user can see @problem
  def user_can_see_problem
    if !@problem.can_be_seen_by(current_user, @no_new_submission)
      render 'errors/access_refused'
    end
  end
  
  # Show flash info with message when user cannot send new submissions
  def show_flash_info_if_no_new_submission
    if signed_in? && current_user.has_sanction_of_type(:no_submission)
      flash.now[:info] = current_user.last_sanction_of_type(:no_submission).message
    end
    if signed_in? && @no_new_submission && (@problem.nil? || !current_user.pb_solved?(@problem))
      flash.now[:info] = @no_new_submission_message
    end
  end
end

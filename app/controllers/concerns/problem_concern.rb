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
end

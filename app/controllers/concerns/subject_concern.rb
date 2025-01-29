#encoding: utf-8

module SubjectConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user can see @subject
  def user_can_see_subject
    if !@subject.can_be_seen_by(current_user)
      render 'errors/access_refused'
    end
  end
end

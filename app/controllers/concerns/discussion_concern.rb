#encoding: utf-8

module DiscussionConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user is involved in the discussion
  def user_is_involved_in_discussion
    if !@discussion.nil? && !current_user.discussions.include?(@discussion)
      render 'errors/access_refused'
    end
  end
end

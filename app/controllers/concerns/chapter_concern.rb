#encoding: utf-8

module ChapterConcern
  extend ActiveSupport::Concern
  include ChaptersHelper
  
  protected
  
  # Check that current user can update @chapter
  def user_can_update_chapter
    unless (signed_in? && (current_user.admin? || (!@chapter.online? && user_can_write_chapter(current_user, @chapter))))
      render 'errors/access_refused'
    end
  end
  
  # Check that current user can see @chapter
  def user_can_see_chapter
    unless @chapter.online || user_can_write_chapter(current_user, @chapter)
      render 'errors/access_refused'
    end
  end
end

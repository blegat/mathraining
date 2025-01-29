#encoding: utf-8
class DiscussionsController < ApplicationController
  include DiscussionConcern
  
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:unread]
  
  before_action :get_discussion, only: [:show, :unread]
  
  before_action :user_is_involved_in_discussion, only: [:show, :unread]
  before_action :user_not_in_skin, only: [:show, :unread]

  # Show 10 messages of a discussion (in html or js)
  def show
    per_page = 10
    page = 1
    if (params.has_key?:page)
      page = params[:page].to_i
    else
      @tchatmessage = Tchatmessage.new # only for html first call
    end
    @tchatmessages = @discussion.get_some_messages(page, per_page)
    @compteur = (page-1) * per_page + 1
    respond_to :html, :js
  end

  # Create a discussion (show the form)
  def new
    if (params.has_key?:qui)
      other = User.find_by_id(params[:qui].to_i)
      return if check_nil_object(other)
      d = Discussion.get_discussion_between(current_user, other)
      unless d.nil?
        redirect_to d and return
      end
    end
    @tchatmessage = Tchatmessage.new
  end
  
  # Mark a discussion as unread
  def unread
    l = current_user.links.where(:discussion_id => @discussion.id).first
    l.update_attribute(:nonread, l.nonread + 1)
    redirect_to new_discussion_path
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the discussion
  def get_discussion
    @discussion = Discussion.find_by_id(params[:id])
    return if check_nil_object(@discussion)
  end
end

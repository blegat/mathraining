#encoding: utf-8
class DiscussionsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:unread]
  
  before_action :get_discussion, only: [:show]
  before_action :get_discussion2, only: [:unread]
  
  before_action :is_involved, only: [:show, :unread]

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

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Create a discussion (show the form)
  def new
    if (params.has_key?:qui)
      other = User.find_by_id(params[:qui].to_i)
      return if check_nil_object(other)
      d = Discussion.get_discussion_between(current_user.sk, other)
      if not d.nil?
        redirect_to d and return
      end
    end
    @tchatmessage = Tchatmessage.new
  end
  
  # Mark a discussion as unread
  def unread
    l = current_user.sk.links.where(:discussion_id => @discussion.id).first
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
  
  # Get the discussion (v2)
  def get_discussion2
    @discussion = Discussion.find_by_id(params[:discussion_id])
    return if check_nil_object(@discussion)
  end
  
  ########## CHECK METHODS ##########

  # Check that current user is involved in the discussion
  def is_involved
    if !current_user.sk.discussions.include?(@discussion)
      render 'errors/access_refused' and return
    elsif current_user.other
      flash[:info] = "Vous ne pouvez pas voir les messages de #{current_user.sk.name}."
      redirect_to new_discussion_path
    end
  end
end

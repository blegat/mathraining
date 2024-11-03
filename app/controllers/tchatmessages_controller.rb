#encoding: utf-8
class TchatmessagesController < ApplicationController
  include DiscussionConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create]
  before_action :user_not_in_skin, only: [:create]
  
  before_action :get_discussion, only: [:create]
  
  before_action :user_is_involved_in_discussion, only: [:create]

  # Create a tchatmessage (send the form)
  def create
    @tchatmessage = Tchatmessage.new(:content    => params[:tchatmessage][:content].strip,
                                     :user       => current_user,
                                     :discussion => @discussion)
    
    new_discussion = false
    if @discussion.nil?
      if !params.has_key?(:qui) || params[:qui].to_i == 0
        error_in_create("Veuillez choisir un destinataire.", true) and return
      else
        other_user = User.find_by_id(params[:qui].to_i)
        error_in_create("Veuillez choisir un destinataire.", true) and return if (other_user.nil? || other_user == current_user)
        @discussion = Discussion.get_discussion_between(current_user, other_user)
        if @discussion.nil?
          @discussion = Discussion.create(:last_message_time => DateTime.now)
          new_discussion = true
        end
      end
    end

    # Invalid CSRF token
    error_in_create(get_csrf_error_message, new_discussion) and return if @invalid_csrf_token
    
    # Check that no new message was posted
    unless new_discussion                             
      link = current_user.links.where(:discussion_id => @discussion.id).first
      if link.nonread > 0
        error_in_create("Un message a été envoyé avant le vôtre.", new_discussion) and return
      end
    end

    if other_user.nil?
      @discussion.users.each do |u|
        if u != current_user
          other_user = u
        end
      end
    end

    @tchatmessage.discussion = @discussion
    
    # Invalid tchatmessage
    error_in_create(nil, new_discussion) and return if !@tchatmessage.valid?
    
    # Attached files
    attach = create_files
    error_in_create(@file_error, new_discussion) and return if !@file_error.nil?

    @tchatmessage.save

    attach_files(attach, @tchatmessage)
    
    if other_user.follow_message
      UserMailer.new_followed_tchatmessage(other_user.id, current_user.id, @discussion.id).deliver
    end
    
    if new_discussion
      Link.create(:user => current_user, :discussion => @discussion, :nonread => 0)
      Link.create(:user => other_user,      :discussion => @discussion, :nonread => 1)
    else    
      @discussion.links.each do |l|
        if l.user_id != current_user.id
          l.update_attribute(:nonread, l.nonread + 1)
        else
          l.update_attribute(:nonread, 0)
        end
      end
    end
    @discussion.update_attribute(:last_message_time, @tchatmessage.created_at)
    redirect_to @discussion
  end
  
  ########## GET METHODS ##########
  
  # Get the discussion
  def get_discussion
    if params[:tchatmessage].has_key?(:discussion_id)
      @discussion = Discussion.find_by_id(params[:tchatmessage][:discussion_id])
      return if check_nil_object(@discussion)
    end
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is involved in the discussion
  def is_involved
    if !@discussion.nil? && !current_user.discussions.include?(@discussion)
      render 'errors/access_refused' and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  def error_in_create(err, new_discussion)
    if new_discussion
      if !@discussion.nil?
        @discussion.destroy
        @discussion = nil
      end
      render_with_error('discussions/new', @tchatmessage, err)
    else
      render_with_error('discussions/show', @tchatmessage, err)
    end
  end
end

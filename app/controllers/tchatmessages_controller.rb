#encoding: utf-8
class TchatmessagesController < ApplicationController
  before_action :signed_in_user_danger, only: [:create]
  before_action :notskin_user, only: [:create]
  
  before_action :get_discussion, only: [:create]
  
  before_action :is_involved, only: [:create]

  # Create a tchatmessage (send the form)
  def create
    @tchatmessage = Tchatmessage.new(:content    => params[:tchatmessage][:content].strip,
                                     :user       => current_user.sk,
                                     :discussion => @discussion)
    
    new_discussion = false
    if @discussion.nil?
      if !params.has_key?(:qui) || params[:qui].to_i == 0
        @tchatmessage.errors.add(:base, "Veuillez choisir un destinataire.")
        render 'discussions/new' and return
      else
        other_user = User.find_by_id(params[:qui].to_i)
        render 'discussions/new' and return if (other_user.nil? || other_user == current_user.sk)
        @discussion = Discussion.get_discussion_between(current_user.sk, other_user)
        if @discussion.nil?
          @discussion = Discussion.create(:last_message_time => DateTime.now)
          new_discussion = true
        end
      end
    end
    
    unless new_discussion                             
      link = current_user.sk.links.where(:discussion_id => @discussion.id).first
      if link.nonread > 0
        @tchatmessage.errors.add(:base, "Un message a été envoyé avant le vôtre.")
        render 'discussions/show' and return
      end
    end

    if other_user.nil?
      @discussion.users.each do |u|
        if u != current_user.sk
          other_user = u
        end
      end
    end
    
    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      @tchatmessage.errors.add(:base, @error_message)
      return error_in_create(new_discussion)
    end

    @tchatmessage.discussion = @discussion
    if !@tchatmessage.save
      destroy_files(attach)
      return error_in_create(new_discussion)
    end

    attach_files(attach, @tchatmessage)
    
    if other_user.follow_message
      UserMailer.new_followed_tchatmessage(other_user.id, current_user.sk.id, @discussion.id).deliver
    end
    
    if new_discussion
      Link.create(:user => current_user.sk, :discussion => @discussion, :nonread => 0)
      Link.create(:user => other_user, :discussion => @discussion, :nonread => 1)
    else    
      @discussion.links.each do |l|
        if l.user_id != current_user.sk.id
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
    if !@discussion.nil? && !current_user.sk.discussions.include?(@discussion)
      render 'errors/access_refused' and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  def error_in_create(new_discussion)
    if new_discussion
      @discussion.destroy
      @discussion = nil
      render 'discussions/new' and return
    else
      render 'discussions/show' and return
    end
  end
end

#encoding: utf-8
class MessagesController < ApplicationController
  include SubjectConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :soft_destroy]
  before_action :admin_user, only: [:destroy]
  
  before_action :get_message, only: [:update, :destroy, :soft_destroy]
  before_action :get_subject, only: [:create]
  before_action :get_q, only: [:create, :update, :destroy, :soft_destroy]
  
  before_action :user_can_see_subject, only: [:create]
  before_action :user_can_update_message, only: [:update, :destroy, :soft_destroy]
  before_action :user_not_in_skin, only: [:create, :update]
  

  # Create a message (send the form)
  def create
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message = Message.new(params.require(:message).permit(:content))
    @message.user = current_user
    @message.subject = @subject

    # Check that no new message was posted
    lastid = -1
    lastmessage = @subject.messages.order("id DESC").first
    if !lastmessage.nil?
      lastid = lastmessage.id
    end

    @page = @subject.last_page # Used in case of error

    if lastid != params[:lastmessage].to_i
      render_with_error('subjects/show', @message, "Un nouveau message a été posté avant le vôtre ! Veuillez en prendre connaissance avant de poster votre message.") and return
    end
    
    # Invalid CSRF token
    render_with_error('subjects/show', @message, get_csrf_error_message) and return if @invalid_csrf_token
    
    # Invalid message
    render_with_error('subjects/show') and return if !@message.valid?

    # Attached files
    attach = create_files
    render_with_error('subjects/show', @message, @file_error) and return if !@file_error.nil?

    @message.save
    
    attach_files(attach, @message)

    # Send an email to users following the subject
    @subject.following_users.each do |u|
      if u != current_user
        if (@subject.for_correctors && !u.corrector? && !u.admin?) || (@subject.for_wepion && !u.wepion? && !u.admin?)
          # Not really normal that this user follows this subject
        else
          UserMailer.new_followed_message(u.id, @subject.id, current_user.id).deliver
        end
      end
    end

    if current_user.root?
      if params.has_key?("emailWepion")
        User.where(:group => ["A", "B"]).each do |u|
          UserMailer.new_message_group(u.id, @subject.id, current_user.id).deliver
        end
      end
    end
    
    flash[:success] = "Votre message a bien été posté."
    redirect_to subject_path(@message.subject, :page => @subject.last_page, :q => @q, :msg => @message.id)
  end

  # Update a message (send the form)
  def update
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message.content = params[:message][:content]
    
    @page = @message.page # Used in case of error
    
    # Invalid CSRF token
    render_with_error('subjects/show', @message, get_csrf_error_message) and return if @invalid_csrf_token
    
    # Invalid message
    render_with_error('subjects/show') and return if !@message.valid?
    
    # Attached files
    update_files(@message)
    render_with_error('subjects/show', @message, @file_error) and return if !@file_error.nil?
    
    @message.save
    
    flash[:success] = "Votre message a bien été modifié."
    @message.reload # To get correct page
    redirect_to subject_path(@subject, :page => @message.page, :q => @q, :msg => @message.id)
  end
  
  # Erase a message without really deleting it (will still appear but shown as deleted)
  def soft_destroy
    @message.update_attribute(:erased, true)
    
    @message.myfiles.each do |f|
      f.fake_del
    end
    
    flash[:success] = "Votre message a bien été supprimé."
    redirect_to subject_path(@subject, :page => @message.page, :q => @q, :msg => @message.id)
  end

  # Delete a message
  def destroy
    page = @message.page
    @message.destroy
    
    @subject.reload
    if @subject.messages.count == 0
      @subject.destroy
      redirect_to subjects_path(:q => @q)
    else
      page = [1,page-1].max if (@subject.messages.count <= (page-1) * 10) # if last message is destroyed and it was alone on its page
      redirect_to subject_path(@subject, :page => page, :q => @q)
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the message
  def get_message
    @message = Message.find_by_id(params[:id])
    return if check_nil_object(@message)
    @subject = @message.subject
  end
  
  # Get the subject
  def get_subject
    @subject = Subject.find_by_id(params[:subject_id])
    return if check_nil_object(@subject)
  end
  
  # Get the "q" value that is used through the forum
  def get_q
    @q = params[:q] if params.has_key?:q
    @q = nil if @q == "all" # avoid q = "all" when there is no filter
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user can update the message
  def user_can_update_message
    unless @message.can_be_updated_by(current_user)
      render 'errors/access_refused'
    end
  end
end

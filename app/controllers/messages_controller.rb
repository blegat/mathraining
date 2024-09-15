#encoding: utf-8
class MessagesController < ApplicationController
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :admin_user, only: [:destroy]
  
  before_action :get_message, only: [:update, :destroy]
  before_action :get_subject, only: [:create]
  before_action :get_q, only: [:create, :update, :destroy]
  
  before_action :user_that_can_see_subject, only: [:create]
  before_action :user_that_can_update_message, only: [:update, :destroy]
  before_action :notskin_user, only: [:create, :update]
  

  # Create a message (send the form)
  def create
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message = Message.new(params.require(:message).permit(:content))
    @message.user = current_user.sk
    @message.subject = @subject

    # Check that no new message was posted
    lastid = -1
    lastmessage = @subject.messages.order("id DESC").first
    if !lastmessage.nil?
      lastid = lastmessage.id
    end

    if lastid != params[:lastmessage].to_i
      error_create(["Un nouveau message a été posté avant le vôtre ! Veuillez en prendre connaissance avant de poster votre message."]) and return
    end
    
    # Invalid CSRF token
    error_create([get_csrf_error_message]) and return if @invalid_csrf_token
    
    # Invalid message
    error_create(@message.errors.full_messages) and return if !@message.valid?

    # Attached files
    attach = create_files
    error_create([@file_error]) and return if !@file_error.nil?

    @message.save
    
    attach_files(attach, @message)

    # Send an email to users following the subject
    @subject.following_users.each do |u|
      if u != current_user.sk
        if (@subject.for_correctors && !u.corrector && !u.admin) || (@subject.for_wepion && !u.wepion && !u.admin)
          # Not really normal that this user follows this subject
        else
          UserMailer.new_followed_message(u.id, @subject.id, current_user.sk.id).deliver
        end
      end
    end

    @subject.update(:last_comment_time => DateTime.now,
                    :last_comment_user => current_user.sk)

    if current_user.sk.root?
      if params.has_key?("emailWepion")
        User.where(:group => ["A", "B"]).each do |u|
          UserMailer.new_message_group(u.id, @subject.id, current_user.sk.id).deliver
        end
      end
    end
      
    page = get_last_page(@subject)
    flash[:success] = "Votre message a bien été posté."
    redirect_to subject_path(@message.subject, :page => page, :q => @q, :msg => @message.id)
  end

  # Update a message (send the form)
  def update
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message.content = params[:message][:content]
    
    # Invalid CSRF token
    error_update([get_csrf_error_message]) and return if @invalid_csrf_token
    
    # Invalid message
    error_update(@message.errors.full_messages) and return if !@message.valid?
    
    # Attached files
    update_files(@message)
    error_update([@file_error]) and return if !@file_error.nil?
    
    @message.save
    
    flash[:success] = "Votre message a bien été modifié."
    @message.reload
    page = get_page(@message)
    redirect_to subject_path(@message.subject, :page => page, :q => @q, :msg => @message.id)
  end

  # Delete a message
  def destroy
    @subject = @message.subject
    page = get_page(@message)
    @message.destroy

    if @subject.messages.size > 0
      last = @subject.messages.order("created_at").last
      @subject.update(:last_comment_time    => last.created_at,
                      :last_comment_user_id => last.user_id)
    else
      @subject.update(:last_comment_time    => @subject.created_at,
                      :last_comment_user_id => @subject.user_id)
    end
    
    page = [1,page-1].max if (@subject.messages.count <= (page-1) * 10) # if last message is destroyed and it was alone on its page
    redirect_to subject_path(@subject, :page => page, :q => @q)
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
  def user_that_can_update_message
    unless @message.can_be_updated_by(current_user.sk)
      render 'errors/access_refused' and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method when an error occurred during create
  def error_create(err)
    @error_case = "errorNewMessage"
    @error_msgs = err
    @error_params = params[:message]
    
    @page = get_last_page(@subject)
    render 'subjects/show'
  end
  
  # Helper method when an error occurred during update
  def error_update(err)
    @error_case = "errorMessage#{@message.id}"
    @error_msgs = err
    @error_params = params[:message]
    
    @message.reload
    @page = get_page(@message)
    render 'subjects/show'
  end
  
  # Helper method to get the last page of a subject
  def get_last_page(s)
    tot = s.messages.count
    return [0,((tot-1)/10).floor].max + 1
  end
  
  # Helper method to get the page of a subject containing a message
  def get_page(m)
    tot = m.subject.messages.where("id <= ?", m.id).count
    return [0,((tot-1)/10).floor].max + 1
  end
end

#encoding: utf-8
class MessagesController < ApplicationController
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

    # Attached files
    @error_message = ""
    attach = create_files
    error_create([@error_message]) and return if !@error_message.empty?

    if @message.save
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
        for g in ["A", "B"] do
          if params.has_key?("groupe" + g)
            User.where(:group => g).each do |u|
              UserMailer.new_message_group(u.id, @subject.id, current_user.sk.id).deliver
            end
          end
        end
      end
      
      page = get_last_page(@subject)
      flash[:success] = "Votre message a bien été posté."
      session["successNewMessage"] = "ok"
      redirect_to subject_path(@message.subject, :page => page, :q => @q)
    else # The message could not be saved correctly
      destroy_files(attach)
      error_create(@message.errors.full_messages)
    end
  end

  # Update a message (send the form)
  def update
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message.content = params[:message][:content]
    if @message.valid?

      # Attached files
      @error_message = ""
      update_files(@message)
      error_update([@error_message]) and return if !@error_message.empty?
      
      @message.save
      @message.reload
      flash[:success] = "Votre message a bien été modifié."
      session["successMessage#{@message.id}"] = "ok"
      page = get_page(@message)
      redirect_to subject_path(@message.subject, :page => page, :q => @q)
    else
      error_update(@message.errors.full_messages) and return
    end
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
  end
  
  # Get the subject
  def get_subject
    @subject = Subject.find_by_id(params[:subject_id])
    return if check_nil_object(@subject)
  end
  
  # Get the "q" value that is used through the forum
  def get_q
    @q = params[:q].to_i if params.has_key?:q
    @q = nil if @q == 0 # avoid q = 0 when there is no filter
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
    session["errorNewMessage"] = err
    session[:oldContent] = params[:message][:content]
    page = get_last_page(@subject)
    redirect_to subject_path(@subject, :page => page, :q => @q)
  end
  
  # Helper method when an error occurred during update
  def error_update(err)
    session["errorMessage#{@message.id}"] = err
    @message.reload
    session[:oldContent] = params[:message][:content]
    page = get_page(@message)
    redirect_to subject_path(@message.subject, :page => page, :q => @q)
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

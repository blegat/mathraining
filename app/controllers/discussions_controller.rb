#encoding: utf-8
class DiscussionsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:create, :unread]
  
  before_action :get_discussion, only: [:show]
  before_action :get_discussion2, only: [:unread]
  
  before_action :is_involved, only: [:show, :unread]

  # Show 10 messages of a discussion (in html or js)
  def show
    nb_mes = 10
    page = 1
    if (params.has_key?:page)
      page = params[:page].to_i
    end
    @tchatmessages = @discussion.tchatmessages.order("created_at DESC").paginate(page: page, per_page: nb_mes)
    @compteur = (page-1) * nb_mes + 1

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
      d = get_discussion_between(current_user.sk, other)
      if not d.nil?
        redirect_to d and return
      end
    end
    @discussion = Discussion.new
  end

  # Create a discussion (send the form)
  def create
    params[:content].strip! if !params[:content].nil?
    if params[:destinataire].to_i == 0
      session[:ancientexte] = params[:content]
      flash[:danger] = "Veuillez choisir un destinataire."
      redirect_to new_discussion_path and return
    else

      @destinataire = User.find_by_id(params[:destinataire])
      return if check_nil_object(@destinataire)
      return if @destinataire == current_user.sk # Hack
      
      @discussion = get_discussion_between(current_user.sk, @destinataire)

      if @discussion.nil?
        deja = false
        @discussion = Discussion.create(:last_message_time => DateTime.now)
      else
        deja = true
        link = current_user.sk.links.where(:discussion_id => @discussion.id).first
        if link.nonread > 0
          session[:ancientexte] = params[:content]
          flash[:danger] = "Un message a été envoyé avant le vôtre."
          redirect_to @discussion and return
        end
      end

      @content = params[:content]

      send_message

      if @erreur
        @discussion.destroy unless deja
        redirect_to new_discussion_path
      else
        if !deja
          Link.create(:user => current_user.sk, :discussion => @discussion, :nonread => 0)
          Link.create(:user => @destinataire, :discussion => @discussion, :nonread => 1)
        else
          @discussion.links.each do |l|
            if l.user != current_user.sk
              l.update_attribute(:nonread, l.nonread + 1)
            else
              l.update_attribute(:nonread, 0)
            end
          end
          @discussion.update_attribute(:last_message_time, DateTime.now)
        end
        redirect_to @discussion
      end
    end
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
  
  ########## HELPER METHODS ##########
  
  # Helper method to get the discussion between two users (if any)
  def get_discussion_between(x, y)
    return Discussion.joins("INNER JOIN links a ON discussions.id = a.discussion_id").joins("INNER JOIN links b ON discussions.id = b.discussion_id").where("a.user_id" => x, "b.user_id" => y).first
  end

  # Helper method to send a message in the discussion
  def send_message
    @tchatmessage = Tchatmessage.new(:content    => @content,
                                     :user       => current_user.sk,
                                     :discussion => @discussion)
    @erreur = false

    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      flash[:danger] = @error_message
      session[:ancientexte] = @content
      @erreur = true
      return
    end

    if @tchatmessage.save
      attach_files(attach, @tchatmessage)
    else
      @erreur = true
      destroy_files(attach)
      session[:ancientexte] = @content
      flash[:danger] = error_list_for(@tchatmessage)
      return
    end

    if !@erreur
      if @destinataire.follow_message
        UserMailer.new_followed_tchatmessage(@destinataire.id, current_user.sk.id, @discussion.id).deliver
      end
    end
  end
end

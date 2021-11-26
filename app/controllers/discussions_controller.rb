#encoding: utf-8
class DiscussionsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:create, :unread]
  before_action :get_discussion, only: [:show]
  before_action :get_discussion2, only: [:unread]
  before_action :is_involved, only: [:show, :unread]

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

  def create
    params[:content].strip! if !params[:content].nil?
    if params[:destinataire].to_i == 0
      session[:ancientexte] = params[:content]
      flash[:danger] = "Veuillez choisir un destinataire."
      redirect_to new_discussion_path and return
    else

      @destinataire = User.find_by_id(params[:destinataire])
      return if check_nil_object(@destinataire)
      
      @discussion = get_discussion_between(current_user.sk, @destinataire)

      if @discussion.nil?
        deja = false
        @discussion = Discussion.new
        @discussion.last_message = DateTime.now
        @discussion.save
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
              l.nonread = l.nonread + 1
            else
              l.nonread = 0
            end
            l.save
          end
          @discussion.last_message = DateTime.now
          @discussion.save
        end
        redirect_to @discussion
      end
    end
  end
  
  # Marquer comme non lu
  def unread
    l = current_user.sk.links.where(:discussion_id => @discussion.id).first
    l.nonread = l.nonread + 1
    l.save
    redirect_to new_discussion_path
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_discussion
    @discussion = Discussion.find_by_id(params[:id])
    return if check_nil_object(@discussion)
  end
  
  def get_discussion2
    @discussion = Discussion.find_by_id(params[:discussion_id])
    return if check_nil_object(@discussion)
  end

  def is_involved
    if !current_user.sk.discussions.include?(@discussion)
      render 'errors/access_refused' and return
    elsif current_user.other
      flash[:info] = "Vous ne pouvez pas voir les messages de #{current_user.sk.name}."
      redirect_to new_discussion_path
    end
  end
  
  def get_discussion_between(x, y)
    return Discussion.joins("INNER JOIN links a ON discussions.id = a.discussion_id").joins("INNER JOIN links b ON discussions.id = b.discussion_id").where("a.user_id" => x, "b.user_id" => y).first
  end

  def send_message
    @tchatmessage = Tchatmessage.new()
    @tchatmessage.content = @content
    @tchatmessage.user = current_user.sk
    @tchatmessage.discussion = @discussion
    @erreur = false

    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      flash[:danger] = @error_message
      session[:ancientexte] = @content
      @erreur = true
      return
    end

    # Si le message a bien été sauvé
    if @tchatmessage.save

      # On enregistre les pièces jointes
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, @tchatmessage)
        attach[j-1].save
        j = j+1
      end
    else
      @erreur = true
      destroy_files(attach, attach.size()+1)
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

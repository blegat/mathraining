#encoding: utf-8
class DiscussionsController < ApplicationController
  before_action :signed_in_user
  before_action :is_involved, only: [:show]

  def show
    par_page = 10
    quelle_page = 1
    if (params.has_key?:page)
      quelle_page = params[:page].to_i
    end
    @tchatmessages = @discussion.tchatmessages.order("created_at DESC").paginate(page: quelle_page, per_page: par_page)
    @compteur = (quelle_page-1) * par_page + 1

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    if (params.has_key?:qui)
      other = User.find(params[:qui].to_i)
      current_user.sk.discussions.each do |d|
        if d.users.include?(other)
          redirect_to d and return
        end
      end
    end
    @discussion = Discussion.new
  end

  def create
    if params[:destinataire].to_i == 0
      session[:ancientexte] = params[:content]
      flash[:danger] = "Veuillez choisir un destinataire."
      redirect_to new_discussion_path and return
    else

      @destinataire = User.find(params[:destinataire])
      deja = false

      current_user.sk.discussions.each do |d|
        if d.users.include?(@destinataire)
          deja = true
          @discussion = d
        end
      end

      if !deja
        @discussion = Discussion.new
        @discussion.last_message = DateTime.now
        @discussion.save
      else
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
        if !deja
          @discussion.destroy
        end
        redirect_to new_discussion_path
      else
        if !deja
          link = Link.new
          link.user_id = current_user.sk.id
          link.discussion_id = @discussion.id
          link.nonread = 0
          link.save

          link2 = Link.new
          link2.user_id = @destinataire.id
          link2.discussion_id = @discussion.id
          link2.nonread = 1
          link2.save
        else
          @discussion.links.each do |l|
            if l.user_id != current_user.sk.id
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

  ########## PARTIE PRIVEE ##########
  private

  def is_involved
    @discussion = Discussion.find(params[:id])
    if !current_user.sk.discussions.include?(@discussion)
      redirect_to new_discussion_path
    elsif current_user.other
      flash[:info] = "Vous ne pouvez pas voir les messages de #{current_user.sk.name}."
      redirect_to new_discussion_path
    end
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
      flash.now[:danger] = @error_message
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
      destroyfiles(attach, attach.size()+1)
      session[:ancientexte] = @content
      if @content.size == 0
        flash[:danger] = "Votre message est vide."
        return
      elsif @content.size > 8000
        flash[:danger] = "Votre message doit faire moins de 8000 caractères."
        return
      else
        flash[:danger] = "Une erreur est survenue."
        return
      end
    end

    if !@erreur
      if @destinataire.follow_message
        UserMailer.new_followed_tchatmessage(@destinataire.id, current_user.sk.name, @tchatmessage.content, @discussion.id).deliver
      end
    end
  end
end

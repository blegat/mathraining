#encoding: utf-8
class DiscussionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :is_involved, only: [:show]

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

  ########## PARTIE PRIVEE ##########
  private

  def is_involved
    @discussion = Discussion.find(params[:id])
    if !current_user.sk.discussions.include?(@discussion)
      redirect_to new_discussion_path
    elsif current_user.other
      flash[:info] = "Vous ne pouvez pas voir les messages de #{current_user.sk.name}"
      redirect_to new_discussion_path
    end
  end

  def send_message
    @tchatmessage = Tchatmessage.new()
    @tchatmessage.content = @content
    @tchatmessage.user = current_user.sk
    @tchatmessage.discussion = @discussion
    @erreur = false

    # Pièces jointes une par une
    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Tchatmessagefile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          session[:ancientexte] = @content
          nom = params["file#{k}".to_sym].original_filename
          flash[:danger] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          @erreur = true
          return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    # On vérifie que les pièces jointes ne sont pas trop grosses
    if totalsize > 5242880
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end

      session[:ancientexte] = @content
      flash[:danger] = "Vos pièces jointes font plus de 5 Mo au total (#{(totalsize.to_f/524288.0).round(3)} Mo)."
      @erreur = true
      return
    end

    # Si le message a bien été sauvé
    if @tchatmessage.save

      # On enregistre les pièces jointes
      j = 1
      while j < i do
        attach[j-1].tchatmessage = @tchatmessage
        attach[j-1].save
        j = j+1
      end
    else
      @erreur = true
      # On supprime les pièces jointes
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
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
  end
end

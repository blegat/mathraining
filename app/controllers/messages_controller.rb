#encoding: utf-8
class MessagesController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :admin_subject_user, only: [:create]
  before_action :author, only: [:update]
  before_action :admin_user, only: [:destroy]
  before_action :valid_chapter
  before_action :online_chapter
  before_action :notskin_user, only: [:create, :update]
  before_action :get_q, only: [:create, :update, :destroy]

  # Créer un message 2
  def create
    params[:message][:content].strip! if !params[:message][:content].nil?
    @message = Message.new(params.require(:message).permit(:content))
    @message.user = current_user.sk
    @message.subject = @subject

    # On vérifie qu'il n'y a pas eu de nouveau message entre
    lastid = -1
    lastmessage = @subject.messages.order("id DESC").first
    if !lastmessage.nil?
      lastid = lastmessage.id
    end

    if lastid != params[:lastmessage].to_i
      error_create(["Un nouveau message a été posté avant le vôtre ! Veuillez en prendre connaissance ci-dessous avant de poster votre message."]) and return
    end

    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      error_create([@error_message]) and return
    end

    # Si le message a bien été sauvé
    if @message.save

      # On enregistre les pièces jointes
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, @message)
        attach[j-1].save
        j = j+1
      end

      # Envoi d'un mail aux utilisateurs suivant le sujet
      @subject.following_users.each do |u|
        if u != current_user
          if (@subject.admin && !u.admin) || (@subject.wepion && !u.wepion && !u.admin)
            # Ce n'est pas vraiment normal qu'il suive ce sujet
          else
            UserMailer.new_followed_message(u.id, @subject.id, current_user.sk.name, @message.content, @message.id).deliver if Rails.env.production?
          end
        end
      end

      @subject.lastcomment = DateTime.current
      @subject.save

      if current_user.sk.admin?
        for g in ["A", "B"] do
          if params.has_key?("groupe" + g)
            User.where(:group => g).each do |u|
              UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, @message.id).deliver if Rails.env.production?
            end
          end
        end
      end
      
      page = getLastPage(@subject)
      flash[:success] = "Votre message a bien été posté."
      session["successNewMessage"] = "ok"
      redirect_to subject_path(@message.subject, :page => page, :q => @q)

      # Si il y a eu un problème : on supprime les pièces jointes
    else
      destroy_files(attach, attach.size()+1)
      error_create(@message.errors.full_messages)
    end
  end

  # Editer un message 2
  def update
    # Si la modification du message réussit
    params[:message][:content].strip! if !params[:message][:content].nil?
    if @message.update_attributes(params.require(:message).permit(:content))

      # Pièces jointes
      @error = false
      @error_message = ""

      attach = update_files(@message, "Message") # Fonction commune pour toutes les pièces jointes

      if @error
        error_update([@error_message]) and return
      end
      
      @message.reload
      flash[:success] = "Votre message a bien été modifié."
      session["successEditMessage#{@message.id}"] = "ok"
      page = getPage(@message)
      redirect_to subject_path(@message.subject, :page => page, :q => @q)

      # Si il y a eu un bug
    else
      error_update(@message.errors.full_messages) and return
    end
  end

  # Supprimer un message : il faut être admin
  def destroy
    @message = Message.find(params[:id])
    @subject = @message.subject

    @message.myfiles.each do |f|
      f.file.destroy
      f.destroy
    end

    @message.fakefiles.each do |f|
      f.destroy
    end

    @message.destroy
    if @subject.messages.size > 0
      last = @subject.messages.order("id").last
      @subject.lastcomment = last.created_at
      @subject.save
    else
      @subject.lastcomment = @subject.created_at
      @subject.save
    end
    redirect_to subject_path(@subject, :q => @q)
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def error_create(err)
    session["errorNewMessage"] = err
    session[:oldContent] = params[:message][:content]
    page = getLastPage(@subject)
    redirect_to subject_path(@subject, :page => page, :q => @q)
  end
  
  def error_update(err)
    session["errorEditMessage#{@message.id}"] = err
    @message.reload
    session[:oldContent] = params[:message][:content]
    page = getPage(@message)
    redirect_to subject_path(@message.subject, :page => page, :q => @q) and return
  end
  
  def get_q
    @q = 0
    @q = params[:q].to_i if params.has_key?:q
  end
  
  def getLastPage(s)
    tot = s.messages.count
    return [0,((tot-1)/10).floor].max + 1
  end
  
  def getPage(m)
    tot = m.subject.messages.where("id <= ?", m.id).count
    return [0,((tot-1)/10).floor].max + 1
  end

  # Il faut que le chapitre existe
  def valid_chapter
    chapter_id = params[:chapter_id]
    if chapter_id.nil?
      @chapter = nil
    else
      @chapter = Chapter.find_by_id(chapter_id)
      redirect_to root_path if @chapter.nil?
    end
  end

  # Il faut que le chapitre soit en ligne ou qu'on soit admin
  def online_chapter
    if @chapter.nil?
      return
    end
    redirect_to sections_path unless (current_user.sk.admin? || @chapter.online)
  end

  # Il faut être admin si le sujet est pour admin
  def admin_subject_user
    @subject = Subject.find(params[:subject_id])
    redirect_to root_path unless (current_user.sk.admin? || current_user.sk.corrector? || !@subject.admin)
  end

  # Il faut être l'auteur ou admin pour modifier un message
  def author
    @message = Message.find(params[:id])
    redirect_to subjects_path unless (current_user.sk == @message.user || (current_user.sk.admin && !@message.user.admin) || current_user.sk.root)
  end
end

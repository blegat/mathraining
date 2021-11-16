#encoding: utf-8
class TchatmessagesController < DiscussionsController
  before_action :signed_in_user_danger, only: [:create]
  before_action :notskin_user, only: [:create]
  before_action :is_involved_2, only: [:create]

  def create
    params[:content].strip! if !params[:content].nil?
    link = current_user.sk.links.where(:discussion_id => @discussion.id).first
    if link.nonread > 0
      session[:ancientexte] = params[:content]
      flash[:danger] = "Un message a été envoyé avant le vôtre."
      redirect_to @discussion and return
    end

    @destinataire = current_user.sk
    @discussion.users.each do |u|
      if u != current_user.sk
        @destinataire = u
      end
    end

    @content = params[:content]

    send_message
    
    if @erreur
      redirect_to @discussion
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
      redirect_to @discussion
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  def is_involved_2
    @discussion = Discussion.find_by_id(params[:tchatmessage][:discussion_id])
    if @discussion.nil?
      render 'errors/access_refused' and return
    end
    if !current_user.sk.discussions.include?(@discussion)
      render 'errors/access_refused' and return
    end
  end
end

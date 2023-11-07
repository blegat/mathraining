#encoding: utf-8
class TchatmessagesController < DiscussionsController
  before_action :signed_in_user_danger, only: [:create]
  before_action :notskin_user, only: [:create]
  
  before_action :get_discussion2, only: [:create]
  
  before_action :is_involved, only: [:create]

  # Create a tchatmessage (send the form)
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
          l.update_attribute(:nonread, l.nonread + 1)
        else
          l.update_attribute(:nonread, 0)
        end
      end
      @discussion.update_attribute(:last_message_time, DateTime.now)
      redirect_to @discussion
    end
  end
end

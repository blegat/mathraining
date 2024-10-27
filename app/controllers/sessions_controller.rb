#encoding: utf-8
class SessionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:destroy]
  before_action :signed_out_user, only: [:create]

  # Create a session, i.e. sign in (send the form)
  def create
    email = params[:session][:email].downcase
    user = User.where(:email => email).first
    
    if user && user.authenticate(params[:session][:password])
      if !user.active # NB: The email of inactive accounts is set to the id of the user, so this should not happen in general
        flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
        redirect_back(fallback_location: root_path)
      elsif user.is_banned
        flash[:danger] = "Ce compte a été temporairement désactivé pour cause de plagiat. Il sera à nouveau accessible le " + write_date(user.end_of_ban) + ". L'équipe des correcteurs bénévoles de Mathraining vous invite à prendre de ce temps libre pour réfléchir à l'intérêt de leur faire corriger des solutions qui ne viennent pas de vous. Notez que la création d'un second compte est formellement interdite et résulterait en une sanction encore plus sévère que celle-ci."
        redirect_back(fallback_location: root_path)
      elsif user.email_confirm
        @remember_me = params[:session][:remember_me].to_i
        user.save
        sign_in user
        redirect_back(fallback_location: root_path)
      else
        flash[:danger] = "Vous devez activer votre compte via l'e-mail qui vous a été envoyé."
        redirect_back(fallback_location: root_path)
      end
    else
      flash[:danger] = "Email ou mot de passe invalide."
      redirect_back(fallback_location: root_path)
    end
  end

  # Delete a session, i.e. sign out
  def destroy
    sign_out
    redirect_to root_path
  end
end

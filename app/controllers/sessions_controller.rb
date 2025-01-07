#encoding: utf-8
class SessionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:destroy]
  before_action :signed_out_user, only: [:create]

  # Create a session, i.e. sign in (send the form)
  def create
    email = params[:session][:email].downcase
    user = User.where(:email => email).first
    
    if user && user.active && user.authenticate(params[:session][:password])
      last_ban = user.last_ban
      if !last_ban.nil? && last_ban.end_time > DateTime.now
        flash[:danger] = last_ban.message
        redirect_back(fallback_location: root_path)
      elsif user.email_confirm
        remember_me = (params[:session][:remember_me].to_i == 1)
        sign_in(user, remember_me)
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

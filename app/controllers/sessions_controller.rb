#encoding: utf-8
class SessionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:destroy]
  before_action :signed_out_user, only: [:create, :new]

  # Create a session, i.e. sign in (show the form)
  def new
  end

  # Create a session, i.e. sign in (send the form)
  def create
    email = params[:session][:email].downcase
    user = User.where(:email => email).first
    
    if user && user.authenticate(params[:session][:password])
      if !user.active
        flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
        redirect_back(fallback_location: root_path)
      elsif user.email_confirm
        @remember_me = params[:session][:remember_me].to_i
        user.save
        sign_in user
        redirect_back_or(root_path) # This method works together with store_location inside signed_in_user, to redirect to the previous location
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

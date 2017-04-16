#encoding: utf-8
class SessionsController < ApplicationController
  before_action :signed_out_user, only: [:create, :new]

  # Se connecter 1
  def new
  end

  # Se connecter 2
  def create
    user = User.where(:email => params[:session][:email]).first

    if user && user.authenticate(params[:session][:password])
      if !user.active
        flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
        redirect_back(fallback_location: root_path)
      elsif user.email_confirm
        @remember_me = params[:session][:remember_me].to_i
        user.save
        sign_in user
        redirect_back(fallback_location: root_path)
      else
        flash[:danger] = 'Vous devez activer votre compte via le mail qui vous a été envoyé.'
        redirect_back(fallback_location: root_path)
      end
    else
      flash[:danger] = 'Email ou mot de passe invalide.'
      redirect_back(fallback_location: root_path)
    end
  end

  # Se déconnecter
  def destroy
    sign_out
    redirect_to root_path
  end

  ########## PARTIE PRIVEE ##########
  private

  # Il ne faut pas être connecté pour se connecter
  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end

end

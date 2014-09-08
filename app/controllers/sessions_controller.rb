#encoding: utf-8
class SessionsController < ApplicationController
  before_filter :signed_out_user,
    only: [:create, :new]

  def new
  end
  def create
    user = User.find_by_email(params[:session][:email])
    
    if user && user.authenticate(params[:session][:password])
      if !user.active
        flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
        redirect_to(:back)
      elsif user.email_confirm
        
        sign_in user
        redirect_to(:back)
      else
        flash[:danger] = 'Vous devez activer votre compte via le mail qui vous a été envoyé.'
        redirect_to(:back)
      end
    else
      flash[:danger] = 'Email ou mot de passe invalide.'
      redirect_to(:back)
    end
  end
  def destroy
    sign_out
    redirect_to root_path
  end

  private

  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end

end

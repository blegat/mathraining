#encoding: utf-8
class SessionsController < ApplicationController
  before_filter :signed_out_user,
    only: [:create, :new]

  def new
  end
  def create
    user = User.find_by_email(params[:session][:email])
    if user && user.authenticate(params[:session][:password])
      if user.email_confirm
        flash[:success] = 'Bienvenue sur Mathraining!'
        sign_in user
        redirect_back_or root_path
      else
        flash.now[:error] = 'Vous devez activer votre compte via le mail qui vous a été envoyé.'
        render 'new'
      end
    else
      flash.now[:error] = 'Email ou mot de passe invalide.'
      render 'new'
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

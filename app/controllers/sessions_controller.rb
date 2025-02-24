#encoding: utf-8
class SessionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:destroy]
  before_action :signed_out_user, only: [:create]

  # Create a session, i.e. sign in (send the form)
  def create
    email = params[:session][:email].downcase
    user = User.where(:email => email).first
    password = params[:session][:password]
    if user && !user.deleted? && user.authenticate(password)
      last_ban = user.last_ban
      if !last_ban.nil? && last_ban.end_time > DateTime.now
        flash[:danger] = last_ban.message
      elsif @temporary_closure && !user.admin? && !user.corrector? && !user.wepion?
        flash[:info] = @temporary_closure_message
      elsif !user.email_confirm
        flash[:danger] = "Vous devez activer votre compte via l'e-mail qui vous a été envoyé."
      else
        remember_me = (params[:session][:remember_me].to_i == 1)
        sign_in(user, remember_me)
        if user.unknown_password?
          if password.size >= 8 && password =~ /[A-Z]/ && password =~ /[a-z]/ && password =~ /[0-9]/
            user.strong_password!
          else
            user.weak_password!
          end
        end
      end
    else
      flash[:danger] = "Email ou mot de passe invalide."
    end
    redirect_back(fallback_location: root_path)
  end
  
  # Create a session, to go faster than always filling the form (NOT IN PRODUCTION)
  def fast_create
    unless Rails.env.production?
      sign_out if signed_in?
      user = User.find_by_id(params[:id].to_i)
      sign_in(user, false) unless user.nil?
    end
    redirect_back(fallback_location: root_path)
  end

  # Delete a session, i.e. sign out
  def destroy
    sign_out
    redirect_to root_path
  end
end

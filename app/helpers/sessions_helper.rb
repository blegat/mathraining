#encoding: utf-8
module SessionsHelper
  def sign_in(user)
    if !@remember_me.nil? && @remember_me != 0
      cookies.permanent[:remember_token] = user.remember_token
    else
      cookies[:remember_token] = user.remember_token
    end
    @current_user = user
  end

  def signed_in?
    !current_user.nil?
  end

  def current_user
    if @current_user.nil? && !cookies[:remember_token].nil?
      @current_user = User.find_by_remember_token(cookies[:remember_token])
      if !@current_user.nil?
        mtn = DateTime.now.in_time_zone.to_date
        if mtn != @current_user.last_connexion_date
          @current_user.last_connexion_date = mtn
          @current_user.save
        end
      end
    end
    return @current_user
  end

  def sign_out
    @current_user = nil
    cookies.delete(:remember_token)
  end
end

#encoding: utf-8
module SessionsHelper
  def sign_in(user, remember_me)
    if remember_me
      cookies.permanent[:remember_token] = user.remember_token
    else
      cookies[:remember_token] = user.remember_token
    end
  end

  def signed_in?
    !current_user(false).nil?
  end

  def current_user(use_skin = true)
    if @current_user.nil? && !cookies[:remember_token].nil? # Compute @current_user based on cookie, if not already done
      @current_user = User.find_by_remember_token(cookies[:remember_token])
      if !@current_user.nil?
        mtn = DateTime.now.in_time_zone.to_date
        if mtn != @current_user.last_connexion_date
          @current_user.last_connexion_date = mtn
          @current_user.save
        end
      end
    end
    return @current_user if !use_skin # Do not use skin if not asked to
    return @current_user_sk if !@current_user_sk.nil? # Skin already computed
    if @current_user.nil? || !@current_user.root? || @current_user.skin == 0
      @current_user_sk = @current_user # No skin
    else
      @current_user_sk = User.find_by_id(@current_user.skin)
    end
    return @current_user_sk
  end
  
  def in_skin?
    u = current_user(false)
    return !u.nil? && u.root? && u.skin != 0
  end

  def sign_out
    @current_user = nil
    @current_user_sk = nil
    cookies.delete(:remember_token)
  end
end

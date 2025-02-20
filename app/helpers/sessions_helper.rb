#encoding: utf-8
module SessionsHelper
  def sign_in(user, remember_me)
    if remember_me
      cookies.permanent[:remember_token] = { :value => user.remember_token, :httponly => true }
    else
      cookies[:remember_token] = { :value => user.remember_token, :httponly => true }
    end
    @current_user_computed = nil
  end
  
  def sign_out
    cookies.delete(:remember_token)
    @current_user_computed = nil
  end
  
  def compute_current_user
    return if !@current_user_computed.nil? # Already computed
    @current_user = nil
    @current_user_sk = nil
    @current_user_computed = true
    
    if !cookies[:remember_token].nil?
      @current_user = User.find_by_remember_token(cookies[:remember_token])
    end
    
    return if @current_user.nil?
    
    if @current_user.root? && @current_user.skin != 0
      @current_user_sk = User.find_by_id(@current_user.skin)
    else
      @current_user_sk = @current_user # No skin
    end
  end
  
  def signed_in?
    compute_current_user
    return !@current_user.nil?
  end

  def current_user
    compute_current_user
    return @current_user_sk
  end
  
  def current_user_no_skin
    compute_current_user
    return @current_user
  end
  
  def in_skin?
    compute_current_user
    return @current_user_sk.id != @current_user.id
  end
end

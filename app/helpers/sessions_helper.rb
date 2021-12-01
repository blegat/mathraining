#encoding: utf-8
module SessionsHelper
  def sign_in(user)
    if !@remember_me.nil? && @remember_me != 0
      cookies.permanent[:remember_token] = user.remember_token
    else
      cookies[:remember_token] = user.remember_token
    end
    @current_user = user
    @signed_in = true
  end

  def signed_in?
    !current_user.nil?
  end

  def current_user
    if @current_user.nil?
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
    @signed_in = false
    cookies.delete(:remember_token)
  end

  def redirect_back_or(default)
    retour = session[:return_to]
    session.delete(:return_to)
    # On redirige vers la page "retour" si et seulement si on vient de la page signin!
    if(retour and params[:redirection] == "/signin")
      redirect_to(retour)
    else
      redirect_back(fallback_location: default)
    end
  end

  def store_location
    session[:return_to] = request.fullpath
  end
end

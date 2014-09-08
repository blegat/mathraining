#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper
  include MarkdownHelper
  
  before_filter :active_user
  
  private
  
  def active_user
    if signed_in? && !current_user.active
      flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
      sign_out
      redirect_to root_path
    end
  end
end

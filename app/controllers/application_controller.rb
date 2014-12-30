#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper
  include MarkdownHelper
  
  before_filter :active_user
  before_filter :check_up
  
  private
  
  def active_user
    if signed_in? && !current_user.active
      flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
      sign_out
      redirect_to root_path
    end
  end
  
  def check_up
    maintenant = DateTime.now.to_i
    Takentest.where(status: 0).each do |t|
      debut = t.takentime.to_i
      if debut + t.virtualtest.duration*60 < maintenant
        t.status = 1
        t.save
        u = t.user
        v = t.virtualtest
        v.problems.each do |p|
          p.submissions.where(user_id: u.id, intest: true).each do |s|
            s.visible = true
            s.save
          end
        end
      end
    end
  end
end

#encoding: utf-8
class StaticPagesController < ApplicationController
  skip_before_action :user_has_some_actions_to_take, only: [:about, :contact]

  # Home page
  def home
    flash.now[:info] = @temporary_closure_message if @temporary_closure
    @actualities = Actuality.order("created_at DESC").paginate(:page => params[:page], :per_page => 5)
  end
  
  # About page
  def about
  end
  
  # Contact page
  def contact
  end
  
  # General statistics page
  def stats
  end
end

#encoding: utf-8
class StaticPagesController < ApplicationController

  # Home page
  def home
    flash.now[:info] = @temporary_closure_message if @temporary_closure
    @actualities = Actuality.order("created_at DESC").paginate(:page => params[:page], :per_page => 5)
  end
end

#encoding: utf-8
class StaticPagesController < ApplicationController
  def home
    @actualities = Actuality.order("created_at DESC").paginate(:page => params[:page], :per_page => 5)
  end
end

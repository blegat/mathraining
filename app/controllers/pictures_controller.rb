#encoding: utf-8
class PicturesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user
  before_filter :good_person,
    only: [:show]

  def show
    
  end
  
  def new
    @pic = Picture.new
  end

  def create
    @pic = Picture.new(params[:picture])
    if @pic.save
      flash[:success] = "Image ajoutée."
      redirect_to @pic
    else
      render 'new'
    end
  end

  private
  
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  
  def good_person
    @pic = Picture.find(params[:id])
    redirect_to root_path unless @pic.user.id == current_user.id
  end

end

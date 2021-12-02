#encoding: utf-8
class PicturesController < ApplicationController
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:create, :destroy]
  
  before_action :get_picture, only: [:show, :destroy]
  
  before_action :admin_user_or_chapter_creator
  before_action :author, only: [:show, :destroy]

  # Show one picture
  def show
  end

  # Create a picture (show the form)
  def new
    @picture = Picture.new
  end

  # Create a picture (send the form)
  def create
    @picture = Picture.new(params.require(:picture).permit(:user_id, :image))
    if @picture.save
      flash[:success] = "Image ajoutée."
      redirect_to @picture
    else
      render 'new'
    end
  end

  # Delete a picture
  def destroy
    @picture.destroy
    redirect_to pictures_path
  end

  private
  
  ########## GET METHODS ##########

  # Get the picture
  def get_picture
    @picture = Picture.find_by_id(params[:id])
    return if check_nil_object(@picture)
  end
  
  ########## CHECK METHODS ##########

  # Check that current user is admin or is creating a chapter
  def admin_user_or_chapter_creator
    if !@signed_in || (!current_user.sk.admin && current_user.sk.chaptercreations.count == 0)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is the author of the picture
  def author
    if @picture.user.id != current_user.sk.id
      render 'errors/access_refused' and return
    end
  end

end

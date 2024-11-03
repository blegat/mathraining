#encoding: utf-8
class PicturesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new]
  before_action :signed_in_user_danger, only: [:create, :destroy]
  
  before_action :get_picture, only: [:show, :destroy, :image]
  
  before_action :chapter_creator_or_admin, only: [:index, :show, :new, :create, :destroy]
  before_action :author_of_picture_or_root, only: [:show, :destroy]
  before_action :check_access_key, only: [:image]
  
  # Show all pictures
  def index
  end

  # Show one picture
  def show
  end
  
  # Create a picture (show the form)
  def new
    @picture = Picture.new
  end

  # Create a picture (send the form)
  def create
    @picture = Picture.new(params.require(:picture).permit(:image))
    @picture.user = current_user
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
  
  # Used to have a permanent link /picture/[:id]/image?key=[:access_key]
  def image
    redirect_to url_for(@picture.image)
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
  def chapter_creator_or_admin
    if !signed_in? || (!current_user.admin && current_user.creating_chapters.count == 0)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is the author of the picture
  def author_of_picture_or_root
    if @picture.user.id != current_user.id && !current_user.root?
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the access key is present and correct
  def check_access_key
    if !params.has_key?:key or params[:key] != @picture.access_key
      render 'errors/access_refused' and return
    end
  end
end

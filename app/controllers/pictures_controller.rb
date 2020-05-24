#encoding: utf-8
class PicturesController < ApplicationController
  before_action :signed_in_user, only: [:show, :new]
  before_action :signed_in_user_danger, only: [:create, :destroy]
  before_action :admin_user_or_chapter_creator
  before_action :get_picture, only: [:show, :destroy]
  before_action :good_person, only: [:show, :destroy]

  # Voir, il faut être la bonne personne
  def show
  end

  # Créer
  def new
    @pic = Picture.new
  end

  # Créer 2
  def create
    @pic = Picture.new((params.require(:picture).permit(:user_id, :image)))
    if @pic.save
      flash[:success] = "Image ajoutée."
      redirect_to @pic
    else
      render 'new'
    end
  end

  # Supprimer, il faut être la bonne personne
  def destroy
    @pic.image.destroy
    @pic.destroy
    redirect_to pictures_path
  end

  ########## PARTIE PRIVEE ##########
  private

  def get_picture
    @pic = Picture.find_by_id(params[:id])
    if @pic.nil?
      render 'errors/access_refused' and return
    end
  end

  def admin_user_or_chapter_creator
    if !@signed_in || (!current_user.sk.admin && current_user.sk.chaptercreations.count == 0)
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie qu'il s'agit de la bonne personne
  def good_person
    if @pic.user.id != current_user.sk.id
      render 'errors/access_refused' and return
    end
  end

end

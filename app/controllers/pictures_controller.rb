#encoding: utf-8
class PicturesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user
  before_filter :good_person, only: [:show, :destroy]

  # Voir, il faut être la bonne personne
  def show
  end

  # Créer
  def new
    @pic = Picture.new
  end
  
  # Créer 2
  def create
    @pic = Picture.new(params[:picture])
    if @pic.save
      flash[:success] = "Image ajoutée."
      redirect_to @pic
    else
      render 'new'
    end
  end

  # Supprimer, il faut être la bonne personne
  def destroy
    @pic = Picture.find(params[:id])
    @pic.image.destroy
    @pic.destroy
    redirect_to pictures_path
  end
  
  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'il s'agit de la bonne personne
  def good_person
    @pic = Picture.find(params[:id])
    redirect_to root_path unless @pic.user.id == current_user.sk.id
  end

end

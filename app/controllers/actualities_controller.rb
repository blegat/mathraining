#encoding: utf-8
class ActualitiesController < ApplicationController
  before_action :signed_in_user, only: [:edit, :new]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create]
  before_action :admin_user, only: [:destroy, :update, :edit, :new, :create]
  before_action :get_actuality, only: [:edit, :update, :destroy]

  # Création d'une actualité : que pour les admins
  def new
    @actuality = Actuality.new
  end

  # Editer une actualité : que pour les admins
  def edit
  end
  
  # Création d'une actualité 2 : que pour les admins
  def create
    @actuality = Actuality.create(params.require(:actuality).permit(:title, :content))
    if @actuality.save
      flash[:success] = "Actualité ajoutée."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Editer une actualité 2 : que pour les admins
  def update
    if @actuality.update_attributes(params.require(:actuality).permit(:title, :content))
      flash[:success] = "Actualité modifiée."
      redirect_to root_path
    else
      render 'edit'
    end
  end

  # Supprimer une actualité : que pour les admins
  def destroy
    @actuality.destroy
    flash[:success] = "Actualité supprimée."
    redirect_to root_path
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  def get_actuality
    @actuality = Actuality.find_by_id(params[:id])
    if @actuality.nil?
      render 'errors/access_refused' and return
    end
  end
end

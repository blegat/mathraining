#encoding: utf-8
class CategoriesController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create]
  before_action :root_user
  before_action :get_category, only: [:update, :destroy]

  # Page des catégories
  def index
  end

  # Créer une catégorie
  def create
    @category = Category.new(params.require(:category).permit(:name))
    if @category.save
      flash[:success] = "Catégorie ajoutée."
    else
      flash[:danger] = error_list_for(@category)
    end
    redirect_to categories_path
  end

  # Modifier un niveau
  def update
    if @category.update_attributes(params.require(:category).permit(:name))
      flash[:success] = "Catégorie modifiée."
    else
      flash[:danger] = error_list_for(@category)
    end
    redirect_to categories_path
  end

  # Supprimer un niveau
  def destroy
    @category.destroy
    flash[:success] = "Catégorie supprimée."
    redirect_to categories_path
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  def get_category
    @category = Category.find_by_id(params[:id])
    return if check_nil_object(@category)
  end

end

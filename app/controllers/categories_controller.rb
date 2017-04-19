#encoding: utf-8
class CategoriesController < ApplicationController
  before_action :signed_in_user
  before_action :root_user

  # Page des catégories
  def index
  end

  # Créer une catégorie
  def create
    @category = Category.new(params[:category])
    if @category.save
      flash[:success] = "Catégorie ajoutée."
      redirect_to categories_path
    else
      flash[:danger] = "Une erreur est survenue."
      redirect_to categories_path
    end
  end

  # Modifier un niveau
  def update
    @category = Category.find(params[:id])
    if @category.update_attributes(params[:category])
      flash[:success] = "Catégorie modifiée."
      redirect_to categories_path
    else
      flash[:danger] = "Une erreur est survenue."
      redirect_to categories_path
    end
  end

  # Supprimer un niveau
  def destroy
    @category = Category.find(params[:id])
    @category.destroy
    flash[:success] = "Catégorie supprimée."
    redirect_to categories_path
  end

end

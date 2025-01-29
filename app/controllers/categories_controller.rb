#encoding: utf-8
class CategoriesController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:index, :create, :update, :destroy]
  
  before_action :get_category, only: [:update, :destroy]

  # Show all categories (with fields and links to modify them)
  def index
  end

  # Create a category (send the form)
  def create
    @category = Category.new(params.require(:category).permit(:name))
    if @category.save
      flash[:success] = "Catégorie ajoutée."
    else
      flash[:danger] = error_list_for(@category)
    end
    redirect_to categories_path
  end

  # Update a category (send the form)
  def update
    if @category.update(params.require(:category).permit(:name))
      flash[:success] = "Catégorie modifiée."
    else
      flash[:danger] = error_list_for(@category)
    end
    redirect_to categories_path
  end

  # Delete a category
  def destroy
    @category.destroy
    flash[:success] = "Catégorie supprimée."
    redirect_to categories_path
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the category
  def get_category
    @category = Category.find_by_id(params[:id])
    return if check_nil_object(@category)
  end

end

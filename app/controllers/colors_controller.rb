#encoding: utf-8
class ColorsController < ApplicationController
  before_filter :signed_in_user
  before_filter :root_user

  def new
  end

  def edit
  end

  def create
     @color = Color.new(params[:color])
     if @color.save
      flash[:success] = "Niveau et couleur ajoutés."
      redirect_to colors_path
    else
      flash[:error] = "Une erreur est survenue."
      redirect_to colors_path
    end
  end

  def update
    @color = Color.find(params[:id])
    if @color.update_attributes(params[:color])
      flash[:success] = "Niveau et couleur modifiés."
      redirect_to colors_path
    else
      flash[:error] = "Une erreur est survenue."
      redirect_to colors_path
    end
  end

  def destroy
    @color = Color.find(params[:id])
    @color.destroy
    flash[:success] = "Niveau et couleur supprimés."
    redirect_to colors_path
  end

  private

  def root_user
    redirect_to root_path unless current_user.sk.root
  end

end

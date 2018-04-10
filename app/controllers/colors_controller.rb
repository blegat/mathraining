#encoding: utf-8
class ColorsController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create]
  before_action :root_user
  
  def index
  end

  # Créer un niveau
  def create
    @color = Color.new(params.require(:color).permit(:pt, :name, :femininename, :color, :font_color))
    if @color.save
      flash[:success] = "Niveau et couleur ajoutés."
      redirect_to colors_path
    else
      flash[:danger] = "Une erreur est survenue."
      redirect_to colors_path
    end
  end

  # Modifier un niveau
  def update
    @color = Color.find(params[:id])
    if @color.update_attributes(params.require(:color).permit(:pt, :name, :femininename, :color, :font_color))
      flash[:success] = "Niveau et couleur modifiés."
      redirect_to colors_path
    else
      flash[:danger] = "Une erreur est survenue."
      redirect_to colors_path
    end
  end

  # Supprimer un niveau
  def destroy
    @color = Color.find(params[:id])
    @color.destroy
    flash[:success] = "Niveau et couleur supprimés."
    redirect_to colors_path
  end

end

#encoding: utf-8
class ColorsController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create]
  before_action :root_user
  before_action :get_color, only: [:update, :destroy]
  
  def index
  end

  # Créer un niveau
  def create
    @color = Color.new(params.require(:color).permit(:pt, :name, :femininename, :color))
    if @color.save
      flash[:success] = "Niveau et couleur ajoutés."
    else
      flash[:danger] = error_list_for(@color)
    end
    redirect_to colors_path
  end

  # Modifier un niveau
  def update
    if @color.update_attributes(params.require(:color).permit(:pt, :name, :femininename, :color))
      flash[:success] = "Niveau et couleur modifiés."
    else
      flash[:danger] = error_list_for(@color)
    end
    redirect_to colors_path
  end

  # Supprimer un niveau
  def destroy
    @color.destroy
    flash[:success] = "Niveau et couleur supprimés."
    redirect_to colors_path
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  def get_color
    @color = Color.find_by_id(params[:id])
    return if check_nil_object(@color)
  end

end

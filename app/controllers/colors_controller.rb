#encoding: utf-8
class ColorsController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create]
  before_action :root_user
  
  before_action :get_color, only: [:update, :destroy]
  
  # Show all colors (with fields and links to modify them)
  def index
  end

  # Create a color (send the form)
  def create
    @color = Color.new(params.require(:color).permit(:pt, :name, :femininename, :color, :dark_color))
    if @color.save
      flash[:success] = "Niveau et couleur ajoutés."
    else
      flash[:danger] = error_list_for(@color)
    end
    redirect_to colors_path
  end

  # Update a color (send the form)
  def update
    if @color.update(params.require(:color).permit(:pt, :name, :femininename, :color, :dark_color))
      flash[:success] = "Niveau et couleur modifiés."
    else
      flash[:danger] = error_list_for(@color)
    end
    redirect_to colors_path
  end

  # Delete a color
  def destroy
    @color.destroy
    flash[:success] = "Niveau et couleur supprimés."
    redirect_to colors_path
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the color
  def get_color
    @color = Color.find_by_id(params[:id])
    return if check_nil_object(@color)
  end

end

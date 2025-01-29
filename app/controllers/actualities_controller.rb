#encoding: utf-8
class ActualitiesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy]
  
  before_action :get_actuality, only: [:edit, :update, :destroy]

  # Create an actuality (show the form)
  def new
    @actuality = Actuality.new
  end

  # Update an actuality (show the form)
  def edit
  end
  
  # Create an actuality (send the form)
  def create
    @actuality = Actuality.create(params.require(:actuality).permit(:title, :content))
    if @actuality.save
      flash[:success] = "Actualité ajoutée."
      redirect_to root_path
    else
      render 'new'
    end
  end

  # Update an actuality (send the form)
  def update
    if @actuality.update(params.require(:actuality).permit(:title, :content))
      flash[:success] = "Actualité modifiée."
      redirect_to root_path
    else
      render 'edit'
    end
  end

  # Deletes an actuality
  def destroy
    @actuality.destroy
    flash[:success] = "Actualité supprimée."
    redirect_to root_path
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the actuality
  def get_actuality
    @actuality = Actuality.find_by_id(params[:id])
    return if check_nil_object(@actuality)
  end
end

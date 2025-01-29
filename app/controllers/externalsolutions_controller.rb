#encoding: utf-8
class ExternalsolutionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :admin_user, only: [:create, :update, :destroy]
  
  before_action :get_externalsolution, only: [:update, :destroy]
  before_action :get_problem, only: [:create]
  
  # Create an external solution
  def create
    externalsolution = Externalsolution.new(:problem => @problem, :url => params[:externalsolution][:url])
    if externalsolution.save
      flash[:success] = "Solution externe enregistrée."
    else
      flash[:danger] = error_list_for(externalsolution)
    end
    redirect_to manage_externalsolutions_problem_path(@problem)
  end
  
  # Update an external solution
  def update
    if @externalsolution.update(params.require(:externalsolution).permit(:url))
      flash[:success] = "Solution externe modifiée."
    else
      flash[:danger] = error_list_for(@externalsolution)
    end
    redirect_to manage_externalsolutions_problem_path(@problem)
  end
  
  # Delete an external solution
  def destroy
    @externalsolution.destroy
    flash[:success] = "Solution externe supprimée."
    redirect_to manage_externalsolutions_problem_path(@problem)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the external solution
  def get_externalsolution
    @externalsolution = Externalsolution.find_by_id(params[:id])
    return if check_nil_object(@externalsolution)
    @problem = @externalsolution.problem
  end
  
  # Get the problem
  def get_problem
    @problem = Problem.find_by_id(params[:problem_id])
    return if check_nil_object(@problem)
  end
  
end

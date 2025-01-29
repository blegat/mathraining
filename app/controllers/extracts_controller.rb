#encoding: utf-8
class ExtractsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :admin_user, only: [:create, :update, :destroy]
  
  before_action :get_extract, only: [:update, :destroy]
  before_action :get_externalsolution, only: [:create]
  
  # Create an extract
  def create
    extract = Extract.new(:externalsolution => @externalsolution, :text => params[:extract][:text])
    if extract.save
      flash[:success] = "Extrait enregistré."
    else
      flash[:danger] = error_list_for(extract)
    end
    redirect_to manage_externalsolutions_problem_path(@problem)
  end
  
  # Update an extract
  def update
    if @extract.update(params.require(:extract).permit(:text))
      flash[:success] = "Extrait modifié."
    else
      flash[:danger] = error_list_for(@extract)
    end
    redirect_to manage_externalsolutions_problem_path(@problem)
  end
  
  # Delete an extract
  def destroy
    @extract.destroy
    flash[:success] = "Extrait supprimé."
    redirect_to manage_externalsolutions_problem_path(@problem)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the extract
  def get_extract
    @extract = Extract.find_by_id(params[:id])
    return if check_nil_object(@extract)
    @externalsolution = @extract.externalsolution
    @problem = @externalsolution.problem
  end
  
  # Get the external solution
  def get_externalsolution
    @externalsolution = Externalsolution.find_by_id(params[:externalsolution_id])
    return if check_nil_object(@externalsolution)
    @problem = @externalsolution.problem
  end
  
end

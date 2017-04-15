#encoding: utf-8
class SectionsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :update]
  before_action :recup
  before_action :admin_user, only: [:edit, :update]

  # Montrer la section
  def show
  end
  
  # Montrer les problèmes de la section
  def showpb
  end
  
  # Editer une section
  def edit
  end
  
  # Editer une section 2
  def update
  if @section.update_attributes(name: params[:section][:name], description: params[:section][:description])
      flash[:success] = "Section modifiée."
      redirect_to @section
    else
      render 'edit'
    end
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  # Récupérer la section
  def recup
    @section = Section.find(params[:id])
    if @section.fondation
  	  @fondation = true
  	else
      @fondation = false
    end
  end
  
end


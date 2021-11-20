#encoding: utf-8
class SectionsController < ApplicationController
  before_action :signed_in_user, only: [:edit]
  before_action :signed_in_user_danger, only: [:update]
  before_action :get_section
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
  def get_section
    @section = Section.find_by_id(params[:id])
    return if check_nil_object(@section)
    @fondation = @section.fondation
  end
end

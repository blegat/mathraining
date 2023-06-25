#encoding: utf-8
class SectionsController < ApplicationController
  before_action :signed_in_user, only: [:edit]
  before_action :signed_in_user_danger, only: [:update]
  before_action :admin_user, only: [:edit, :update]
  
  before_action :get_section

  # Show the chapters of a section
  def show
  end

  # Show the problems of a section
  def showpb
    flash.now[:info] = @no_new_submission_message if @no_new_submission
  end

  # Update a section (show the form)
  def edit
  end

  # Update a section (send the form)
  def update
    if @section.update_attributes(params.require(:section).permit(:name, :abbreviation, :short_abbreviation, :initials, :description))
      flash[:success] = "Section modifiée."
      redirect_to @section
    else
      render 'edit'
    end
  end

  private
  
  ########## GET METHODS ##########

  # Get the section
  def get_section
    @section = Section.find_by_id(params[:id])
    return if check_nil_object(@section)
    @fondation = @section.fondation
  end
end

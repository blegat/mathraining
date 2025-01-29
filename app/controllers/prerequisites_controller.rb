# -*- coding: utf-8 -*-
class PrerequisitesController < ApplicationController
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:create, :destroy]
  before_action :admin_user, only: [:index, :create, :destroy]
  
  before_action :get_prerequisite, only: [:destroy]
  
  before_action :offline_chapter, only: [:destroy]

  # Show the graph of prerequisites
  def index
  end

  # Add one prerequisite to a chapter
  def create
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    return if check_nil_object(chapter)
    return if check_nil_object(prerequisite)
    
    if chapter.online
      flash[:danger] = "Les prérequis d'un chapitre en ligne ne peuvent pas être modifiés."
      redirect_to prerequisites_path and return
    end
    
    if chapter.section.fondation && !prerequisite.section.fondation
      flash[:danger] = "Un chapitre fondamental ne peut pas avoir de prérequis non-fondamentaux."
      redirect_to prerequisites_path and return
    end
    
    if !chapter.section.fondation && prerequisite.section.fondation
      flash[:danger] = "Un chapitre non-fondamental ne peut pas avoir de prérequis fondamentaux."
      redirect_to prerequisites_path and return
    end
    
    pre = Prerequisite.new(:chapter => chapter, :prerequisite => prerequisite)
    if pre.save
      flash[:success] = "Lien ajouté."
      redirect_to prerequisites_path
    else
      flash[:danger] = error_list_for(pre)
      redirect_to prerequisites_path
    end
  end

  # Remove one prerequisite of a chapter
  def destroy
    chapter = @prerequisite.chapter
    @prerequisite.destroy
    flash[:success] = "Prérequis supprimé."
    redirect_to chapter
  end
  
  ########## GET METHODS ##########
  
  # Get the prerequisite
  def get_prerequisite
    @prerequisite = Prerequisite.find_by_id(params[:id])
    return if check_nil_object(@prerequisite)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the chapter is offline
  def offline_chapter
    return if check_online_object(@prerequisite.chapter)
  end
end

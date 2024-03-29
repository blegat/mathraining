# -*- coding: utf-8 -*-
class PrerequisitesController < ApplicationController
  before_action :signed_in_user, only: [:graph_prerequisites]
  before_action :signed_in_user_danger, only: [:add_prerequisite, :remove_prerequisite]
  before_action :admin_user

  # Show the graph of prerequisites
  def graph_prerequisites
  end

  # Add one prerequisite to a chapter
  def add_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    return if check_nil_object(chapter)
    return if check_nil_object(prerequisite)
    
    if chapter.online
      flash[:danger] = "Les prérequis d'un chapitre en ligne ne peuvent pas être modifiés."
      redirect_to graph_prerequisites_path and return
    end
    
    if chapter.section.fondation && !prerequisite.section.fondation
      flash[:danger] = "Un chapitre fondamental ne peut pas avoir de prérequis non-fondamentaux."
      redirect_to graph_prerequisites_path and return
    end
    
    if !chapter.section.fondation && prerequisite.section.fondation
      flash[:danger] = "Un chapitre non-fondamental ne peut pas avoir de prérequis fondamentaux."
      redirect_to graph_prerequisites_path and return
    end
    
    pre = Prerequisite.new(:chapter => chapter, :prerequisite => prerequisite)
    if pre.save
      flash[:success] = "Lien ajouté."
      redirect_to graph_prerequisites_path
    else
      flash[:danger] = error_list_for(pre)
      redirect_to graph_prerequisites_path
    end
  end

  # Remove one prerequisite of a chapter
  def remove_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    return if check_nil_object(chapter)
    return if check_nil_object(prerequisite)
    
    if not chapter.prerequisites.exists?(prerequisite.id)
      flash[:danger] = "Ce lien n'existe pas."
      redirect_to graph_prerequisites_path and return
    end
    
    if chapter.online
      flash[:danger] = "Vous ne pouvez pas supprimer un prérequis à un chapitre en ligne."
      redirect_to graph_prerequisites_path and return
    end
    
    chapter.prerequisites.delete(prerequisite)
    flash[:success] = "Lien supprimé."
    redirect_to graph_prerequisites_path
  end

end

# -*- coding: utf-8 -*-
class PrerequisitesController < ApplicationController
  before_action :signed_in_user, only: [:graph_prerequisites]
  before_action :signed_in_user_danger, only: [:add_prerequisite, :remove_prerequisite]
  before_action :admin_user

  # Graphe des prérequis
  def graph_prerequisites
  end

  # Ajouter un prérequis
  def add_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if prerequisite.nil? || chapter.nil?
      flash[:info] = "Choisissez un chapitre."
      redirect_to graph_prerequisites_path and return
    end
    if chapter.online && !prerequisite.section.fondation
      flash[:danger] = "Vous ne pouvez ajouter un prérequis non fondamental à un chapitre en ligne."
      redirect_to graph_prerequisites_path and return
    end
    if chapter.online && !prerequisite.online
      flash[:danger] = "Pour ajouter à un chapitre en ligne un prérequis fondamental, celui-ci doit être en ligne."
      redirect_to graph_prerequisites_path and return
    end
    pre = Prerequisite.new
    pre.chapter = chapter
    pre.prerequisite = prerequisite
    if pre.save
      flash[:success] = "Lien ajouté."
      redirect_to graph_prerequisites_path
      # Sinon @chapter.available_prerequsites
      # ne prend pas en compte les nouveaux changements
    else
      flash[:danger] = get_errors(pre)
      redirect_to graph_prerequisites_path
    end
  end

  # Supprimer un prérequis
  def remove_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if prerequisite.nil? || chapter.nil?
      flash[:info] = "Choisissez un chapitre."
      redirect_to graph_prerequisites_path and return
    end
    if chapter.online && !prerequisite.section.fondation
      flash[:danger] = "Vous ne pouvez pas supprimer un prérequis non fondamental à un chapitre en ligne."
      redirect_to graph_prerequisites_path and return
    end
    if chapter.prerequisites.exists?(prerequisite)
      chapter.prerequisites.delete(prerequisite)
      flash[:success] = "Lien supprimé."
    else
      flash[:danger] = "Ce lien n'existe pas."
    end
    redirect_to graph_prerequisites_path
  end

end

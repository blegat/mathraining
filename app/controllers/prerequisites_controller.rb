# -*- coding: utf-8 -*-
class PrerequisitesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user

  def graph_prerequisites
  end

  def add_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if prerequisite.nil? || chapter.nil?
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]),
        flash: { notice: "Choisissez un chapitre." } and return
    end
    if chapter.online && !prerequisite.sections.empty?
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]),
        flash: { danger: "Vous ne pouvez ajouter un prérequis non fondamental à un chapitre en ligne." } and return
    end
    if chapter.online && !prerequisite.online
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]),
        flash: { danger: "Pour ajouter à un chapitre en ligne un prérequis fondamental, celui-ci doit être en ligne." } and return
    end
    pre = Prerequisite.new
    pre.chapter = chapter
    pre.prerequisite = prerequisite
    if pre.save
      flash[:success] = "Lien ajouté."
      redirect_to graph_prerequisites_path(:fondement => params[:fondement])
      # Sinon @chapter.available_prerequsites
      # ne prend pas en compte les nouveaux changements
    else
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]), flash: { error: get_errors(pre) };
    end
  end

  def remove_prerequisite
    if params[:fondement] == true
      fond = 1
    else
      fond = 0
    end
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if prerequisite.nil? || chapter.nil?
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]),
        flash: { notice: "Choisissez un chapitre." } and return
    end
    if chapter.online && prerequisite.online
      redirect_to graph_prerequisites_path(:fondement => params[:fondement]),
        flash: { danger: "Vous ne pouvez pas supprimer un prérequis non fondamental à un chapitre en ligne." } and return
    end
    if chapter.prerequisites.exists?(prerequisite)
      chapter.prerequisites.delete(prerequisite)
      flash[:success] = "Lien supprimé."
    else
      flash[:danger] = "Ce lien n'existe pas."
    end
    redirect_to graph_prerequisites_path(:fondement => params[:fondement])
  end

  private

  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end

end

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
      redirect_to graph_prerequisites_path,
        flash: { notice: "Choisissez un chapitre." } and return
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
      redirect_to graph_prerequisites_path, flash: { error: get_errors(pre) };
    end
  end
  
  def remove_prerequisite
    chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if prerequisite.nil? || chapter.nil?
      redirect_to graph_prerequisites_path,
        flash: { notice: "Choisissez un chapitre." } and return
    end
    if chapter.prerequisites.exists?(prerequisite)
      chapter.prerequisites.delete(prerequisite)
      flash[:success] = "Lien supprimé."
    else
      flash[:error] = "Ce lien n'existe pas."
    end
    redirect_to graph_prerequisites_path
  end

  private

  def admin_user
    redirect_to root_path unless current_user.admin?
  end

end

# -*- coding: utf-8 -*-
class PrerequisitesController < ApplicationController
  before_filter :admin_user
  def create
    @chapter = Chapter.find_by_id(params[:prerequisite][:chapter_id])
    prerequisite = Chapter.find_by_id(params[:prerequisite][:prerequisite_id])
    if @chapter.nil?
      # must be a hacker :P
      redirect_to root_path and return
    end
    if prerequisite.nil?
      flash.now[:notice] = "Choisissez un chapitre"
      render "chapters/show" and return
    end
    pre = Prerequisite.new
    pre.chapter = @chapter
    pre.prerequisite = prerequisite
    if pre.save
      flash.now[:success] = "Prérequis ajouté"
      @chapter.reload
      # Sinon @chapter.available_prerequsites
      # ne prend pas en compte les nouveaux changements
    else
      flash_errors(pre)
    end
    render "chapters/show"
  end

  private

  def admin_user
    redirect_to root_path unless current_user.admin?
  end

end

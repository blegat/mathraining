#encoding: utf-8
class TheoriesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create]


  def new
    @theory = Theory.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @theory = Theory.find(params[:id])
  end

  def create
    @theory = Theory.new
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @theory.order = params[:theory][:order]
    @theory.chapter_id = params[:chapter_id]
    if @theory.save
      flash[:success] = "Point théorique ajouté."
      @chapter = Chapter.find(params[:chapter_id])
      redirect_to @chapter
    else
      render 'new'
    end
  end

  def update
    @theory = Theory.find(params[:id])
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @theory.order = params[:theory][:order]
    if @theory.save
      flash[:success] = "Point théorique modifié."
      redirect_to @theory.chapter
    else
      render 'edit'
    end
  end

  def destroy
    @theory = Theory.find(params[:id])
    @chapter = @theory.chapter
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end
  
  private
  
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
end

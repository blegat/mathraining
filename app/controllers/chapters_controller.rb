#encoding: utf-8
class ChaptersController < ApplicationController
  before_filter :signed_in_user
  before_filter :search_section
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create]

  def index
    redirect_to @section
  end

  def show
    @chapter = Chapter.find(params[:id])
  end

  def new
    @chapter = Chapter.new
  end

  def edit
    @chapter = Chapter.find(params[:id])
  end

  def create
    @chapter = Chapter.new(params[:chapter])
    if @chapter.save
      @section.chapters<<@chapter
      flash[:success] = "Chapitre ajouté."
      redirect_to section_chapter_path(@section, @chapter)
    else
      render 'new'
    end
  end

  def update
    @chapter = Chapter.find(params[:id])
    if @chapter.update_attributes(params[:chapter])
      flash[:success] = "Chapitre modifié."
      redirect_to section_chapter_path(@section, @chapter)
    else
      render 'edit'
    end
  end

  def destroy
    @chapter = Chapter.find(params[:id])
    @chapter.destroy
    flash[:success] = "Chapitre supprimé."
    redirect_to @section
  end
  
  def add
  end
  
  private
  def search_section
  @section = Section.find(params[:section_id])
  end
  
  def admin_user
    redirect_to @section unless current_user.admin?
  end
end

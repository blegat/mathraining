#encoding: utf-8
class ChaptersController < ApplicationController
  before_filter :signed_in_user
  before_filter :search_section,
    only: [:show, :edit, :update, :destroy,
      :new, :create, :index]
  before_filter :good_combination,
    only: [:show, :edit, :update, :destroy]
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create,
      :new_to_section, :create_to_section]

  def index
    redirect_to @section
  end

  def show
  end

  def new
    @chapter = Chapter.new
  end

  def edit
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
    if @chapter.update_attributes(params[:chapter])
      flash[:success] = "Chapitre modifié."
      redirect_to section_chapter_path(@section, @chapter)
    else
      render 'edit'
    end
  end

  def destroy
    @chapter.destroy
    flash[:success] = "Chapitre supprimé."
    redirect_to @section
  end
  
  def new_section
    @chapter = Chapter.find(params[:chapter_id])
    @sections_to_add = Section.where('id NOT IN(?)', @chapter.sections)
    @sections_to_remove = @chapter.sections
  end

  def create_section
    chapter = Chapter.find(params[:chapter_id])
    section = Section.find(params[:id])
    chapter.sections << section
    redirect_to chapter_manage_sections_path(chapter)
  end

  def destroy_section
    chapter = Chapter.find(params[:chapter_id])
    section = Section.find(params[:id])
    chapter.sections.delete(section)
    redirect_to chapter_manage_sections_path(chapter)
  end
  
  private
  def search_section
    @section = Section.find(params[:section_id])
  end
  
  def admin_user
    redirect_to @section unless current_user.admin?
  end
  
  def good_combination
    if @section.chapters.exists?(:id => params[:id])
      @chapter = Chapter.find(params[:id])
    else
      flash[:error] = "Page inexistante."
  	  redirect_to @section unless @section.chapters.exists?(:id => params[:id])
  	end
  end
end

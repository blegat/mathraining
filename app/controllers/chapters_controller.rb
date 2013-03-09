#encoding: utf-8
class ChaptersController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create,
      :new_to_section, :create_to_section]

  def index
    redirect_to sections_path
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
      flash[:success] = "Chapitre ajouté."
      redirect_to @chapter
    else
      render 'new'
    end
  end

  def update
    @chapter = Chapter.find(params[:id])
    if @chapter.update_attributes(params[:chapter])
      flash[:success] = "Chapitre modifié."
      redirect_to chapter_path(@chapter)
    else
      render 'edit'
    end
  end

  def destroy
    @chapter = Chapter.find(params[:id])
    @chapter.destroy
    flash[:success] = "Chapitre supprimé."
    redirect_to sections_path
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

  def admin_user
    redirect_to sections_path unless current_user.admin?
  end

end

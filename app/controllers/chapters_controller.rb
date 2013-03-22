#encoding: utf-8
class ChaptersController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create,
      :new_section, :create_section, :destroy_section]
  before_filter :delete_online, only: [:destroy]
  before_filter :online_chapter,
    only: [:show]
  before_filter :fondement_online,
    only: [:new_section, :create_section, :destroy_section]
  before_filter :prerequisites_online,
    only: [:warning, :put_online]

  def index
    redirect_to sections_path
  end

  def show
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
      redirect_to chapter_manage_sections_path(@chapter)
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
    Exercise.where(:chapter_id => params[:id]).each do |e|
      e.destroy
    end
    
    Theory.where(:chapter_id => params[:id]).each do |t|
      t.destroy
    end
    
    Problem.where(:chapter_id => params[:id]).each do |p|
      p.destroy
    end
    
    Qcm.where(:chapter_id => params[:id]).each do |q|
      Choice.where(:qcm_id => q.id).each do |c|
        c.destroy
      end
      q.destroy
    end
    
    redirect_to sections_path
  end
  
  def new_section
    @chapter = Chapter.find(params[:chapter_id])
    @sections_to_remove = @chapter.sections
    if @sections_to_remove.empty?
      # weirdly in NOT IN(?), [] is always false
      @sections_to_add = Section.all
    else
      @sections_to_add = Section.where('id NOT IN(?)', @chapter.sections)
    end
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
    if chapter.online && chapter.sections.count == 1
      flash[:error] = "Un chapitre en ligne non fondamental ne peut pas devenir fondamental. Si vous désirez changer ce chapitre de section, commencez par rajouter la nouvelle section et retirez ensuite l'ancienne."
    else
      chapter.sections.delete(section)
    end
    redirect_to chapter_manage_sections_path(chapter)
  end
  
  def warning
  end
  
  def put_online
    @chapter.online = true
    @chapter.save
    redirect_to @chapter
  end
  
  private

  def admin_user
    redirect_to sections_path unless current_user.admin?
  end
  
  def online_chapter
    @chapter = Chapter.find(params[:id])
    redirect_to sections_path unless (current_user.admin? || @chapter.online)
  end
  
  def delete_online
    @chapter = Chapter.find(params[:id])
    redirect_to sections.path unless @chapter.online
  end
  
  def fondement_online
    @chapter = Chapter.find(params[:chapter_id])
    redirect_to @chapter if (@chapter.online && @chapter.sections.empty?)
  end
  
  def prerequisites_online
    @chapter = Chapter.find(params[:chapter_id])
    @chapter.prerequisites.each do |p|
      if !p.online
        flash[:error] = "Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne."
        redirect_to @chapter and return
      end
    end
    if @chapter.online
      redirect_to @chapter and return	
    end
  end

end

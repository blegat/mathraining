#encoding: utf-8
class ChaptersController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :destroy, :read, :order_minus, :order_plus, :put_online, :switch_submission_prerequisite]
  before_action :admin_user, only: [:new, :create, :destroy, :order_minus, :order_plus]
  before_action :root_user, only: [:put_online, :switch_submission_prerequisite]
  
  before_action :get_chapter, only: [:show, :edit, :update, :destroy]
  before_action :get_chapter2, only: [:read, :order_minus, :order_plus, :put_online, :switch_submission_prerequisite]
  before_action :get_section, only: [:new, :create]
  
  before_action :offline_chapter, only: [:destroy, :put_online]
  before_action :online_chapter_or_creating_user, only: [:show, :read]
  before_action :prerequisites_online, only: [:put_online]
  before_action :user_that_can_update_chapter, only: [:edit, :update]

  # Show one chapter
  def show
  end
  
  # Show statistics of all chapters
  def chapterstats
  end

  # Create a chapter (show the form)
  def new
    @chapter = Chapter.new
  end

  # Update a chapter (show the form)
  def edit
  end

  # Create a chapter (send the form)
  def create
    last_chapter = @section.chapters.where(:level => params[:chapter][:level]).order(:position).last
    if last_chapter.nil?
      position = 1
    else
      position = last_chapter.position + 1
    end
    @chapter = Chapter.new(params.require(:chapter).permit(:name, :description, :level, :author))
    @chapter.section_id = params[:section_id]
    @chapter.position = position
    if @chapter.save
      flash[:success] = "Chapitre ajouté."
      redirect_to chapter_path(@chapter)
    else
      render 'new'
    end
  end

  # Update a chapter (send the form)
  def update
    old_level = @chapter.level
    if @chapter.update(params.require(:chapter).permit(:name, :description, :level, :author))
      if old_level != @chapter.level
        last_chapter = @section.chapters.where(:level => params[:chapter][:level]).order(:position).last
        if last_chapter.nil?
          position = 1
        else
          position = last_chapter.position + 1
        end
        @chapter.position = position
        @chapter.save
      end
      flash[:success] = "Chapitre modifié."
      redirect_to chapter_path(@chapter)
    else
      render 'edit'
    end
  end

  # Delete a chapter
  def destroy
    @chapter.destroy
    flash[:success] = "Chapitre supprimé."
    redirect_to section_path(@section)
  end

  # Mark the full chapter as read
  def read
    @chapter.theories.each do |t|
      if t.online && !current_user.sk.theories.exists?(t.id)
        current_user.sk.theories << t
      end
    end
    redirect_to chapter_path(@chapter, :type => 10)
  end

  # Put the chapter online
  def put_online
    @chapter.online = true
    @chapter.publication_date = Date.today
    @chapter.save
    @section = @chapter.section
    @chapter.questions.each do |q|
      @section.max_score = @section.max_score + q.value
      q.online = true
      q.save
    end
    @chapter.theories.each do |t|
      t.online = true
      t.save
    end
    @section.save
    redirect_to @chapter
  end
  
  # Move the chapter up (in his level)
  def order_minus
    chapter2 = @section.chapters.where("level = ? AND position < ?", @chapter.level, @chapter.position).order('position').last
    unless chapter2.nil?
      swap_position(@chapter, chapter2)
      flash[:success] = "Chapitre déplacé vers le haut."
    end
    redirect_to @chapter
  end

  # Move the chapter down (in his level)
  def order_plus
    chapter2 = @section.chapters.where("level = ? AND position > ?", @chapter.level, @chapter.position).order('position').first
    unless chapter2.nil?
      swap_position(@chapter, chapter2)
      flash[:success] = "Chapitre déplacé vers le bas."
    end
    redirect_to @chapter
  end
  
  # Set or unset this chapter as a prerequisite to send submissions
  def switch_submission_prerequisite
    if !@chapter.submission_prerequisite
      flash[:success] = "Ce chapitre est maintenant prérequis pour écrire une soumission."
    else
      flash[:success] = "Ce chapitre n'est plus prérequis pour écrire une soumission."
    end
    @chapter.toggle!(:submission_prerequisite)
    redirect_to @chapter
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:id])
    return if check_nil_object(@chapter)
    @section = @chapter.section
  end
  
  # Get the chapter (v2)
  def get_chapter2
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
    @section = @chapter.section
  end
  
  # Get the section
  def get_section
    @section = Section.find_by_id(params[:section_id])
    return if check_nil_object(@section)
  end
  
  ########## CHECK METHODS ##########

  # Check that the chapter is online or that current user can see it (creator or admin)
  def online_chapter_or_creating_user
    unless @chapter.online || (@signed_in && (current_user.sk.admin? || current_user.sk.creating_chapters.exists?(@chapter.id)))
      render 'errors/access_refused' and return
    end
  end

  # Check that the chapter is offline
  def offline_chapter
    return if check_online_object(@chapter)
  end

  # Check that the prerequisites are online
  def prerequisites_online
    @chapter.prerequisites.each do |p|
      if !p.online
        flash[:danger] = "Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne."
        redirect_to @chapter and return
      end
    end
  end

end

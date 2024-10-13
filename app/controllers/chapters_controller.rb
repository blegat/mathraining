#encoding: utf-8
class ChaptersController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :read, :order, :put_online, :mark_submission_prerequisite, :unmark_submission_prerequisite]
  before_action :non_admin_user, only: [:read]
  before_action :admin_user, only: [:new, :create, :destroy, :order]
  before_action :root_user, only: [:put_online, :mark_submission_prerequisite, :unmark_submission_prerequisite]
  
  before_action :get_chapter, only: [:show, :edit, :update, :destroy]
  before_action :get_chapter2, only: [:all, :read, :order, :put_online, :mark_submission_prerequisite, :unmark_submission_prerequisite]
  before_action :get_section, only: [:new, :create]
  
  before_action :offline_chapter, only: [:destroy, :put_online]
  before_action :online_chapter, only: [:read]
  before_action :prerequisites_online, only: [:put_online]
  before_action :user_that_can_see_chapter, only: [:show, :all]
  before_action :user_that_can_update_chapter, only: [:edit, :update]

  # Show one chapter (summary only)
  def show
    if(params.has_key?:type)
      # Before, we were using chapters/show to see full chapter, one theory or one question
      # We redirect such old paths to the new paths here, in case such links are used somewhere
      type = params[:type].to_i
      which = 0
      if(params.has_key?:which)
        which = params[:which].to_i
      end
      redirect_to chapter_path(@chapter) and return if type == 0
      redirect_to chapter_all_path(@chapter) and return if type == 10
      redirect_to chapter_theory_path(@chapter, which) and return if type == 1
      redirect_to chapter_question_path(@chapter, which) and return if type == 5
    end
  end
  
  # Show the full chapter
  def all
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
        position = (last_chapter.nil? ? 1 : last_chapter.position + 1)
        @chapter.update_attribute(:position, position)
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
    @chapter.update(:online           => true,
                    :publication_date => Date.today)
    @section = @chapter.section
    @chapter.questions.each do |q|
      @section.max_score = @section.max_score + q.value
      q.update_attribute(:online, true)
    end
    @chapter.theories.each do |t|
      t.update_attribute(:online, true)
    end
    @section.save
    redirect_to @chapter
  end
  
  # Move the chapter to another position
  def order
    chapter2 = @section.chapters.where("level = ? AND position = ?", @chapter.level, params[:new_position]).first
    if !chapter2.nil? and chapter2 != @chapter
      res = swap_position(@chapter, chapter2)
      flash[:success] = "Chapitre déplacé#{res}." 
    end
    redirect_to @chapter
  end
  
  # Set this chapter as a prerequisite to send submissions
  def mark_submission_prerequisite
    flash[:success] = "Ce chapitre est maintenant prérequis pour écrire une soumission."
    @chapter.update_attribute(:submission_prerequisite, true)
    redirect_to @chapter
  end
  
  # Unset this chapter as a prerequisite to send submissions
  def unmark_submission_prerequisite
    flash[:success] = "Ce chapitre n'est plus prérequis pour écrire une soumission."
    @chapter.update_attribute(:submission_prerequisite, false)
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
  
  # Check that the chapter is online
  def online_chapter
    return if check_offline_object(@chapter)
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

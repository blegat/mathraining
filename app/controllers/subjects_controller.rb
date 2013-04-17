#encoding: utf-8
class SubjectsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user, only: [:show]
  before_filter :author, only: [:update, :edit, :destroy]
  before_filter :valid_chapter
  before_filter :online_chapter
  before_filter :unlocked_chapter
  before_filter :admin_delete, only: [:destroy]
  before_filter :whatcolors

  def index
    if current_user.admin?
      if @chapter.nil?
        @importants = Subject.where(important: true).order("lastcomment DESC")
        @subjects = Subject.where(important: false).order("lastcomment DESC").paginate(page: params[:page], per_page: 15)
      else
        @importants = Subject.where(chapter_id: @chapter, important: true).order("lastcomment DESC")
        @subjects = Subject.where(chapter_id: @chapter, important: false).order("lastcomment DESC").paginate(page: params[:page], per_page: 15)
      end
    else
      if @chapter.nil?
        @importants = Subject.where(admin: false, important: true).order("lastcomment DESC")
        @subjects = Subject.where(admin: false, important: false).order("lastcomment DESC").paginate(page: params[:page], per_page: 15)
      else
        @importants = Subject.where(admin: false, chapter_id: @chapter, important: true).order("lastcomment DESC")
        @subjects = Subject.where(admin: false, chapter_id: @chapter, important: false).order("lastcomment DESC").paginate(page: params[:page], per_page: 15)
      end
    end
  end

  def show
    @messages = @subject.messages.order(:id).paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @subject = Subject.new
    if current_user.admin?
      @subject.admin = true
    end
    if @chapter.nil?
      @preselect = 0
    else
      @preselect = @chapter.id
    end
  end

  def edit
    if @subject.chapter.nil?
      @preselect = 0
    else
      @preselect = @subject.chapter.id
    end
  end

  def create
    if !current_user.admin? && !params[:subject][:important].nil? # Hack
      redirect_to root_path
    end
    @subject = Subject.create(params[:subject].except(:chapter_id))
    @subject.user = current_user
    @subject.lastcomment = DateTime.current
    @subject.admin_user = current_user.admin?
    chapter_id = params[:subject][:chapter_id].to_i
    if chapter_id != 0
      @chapitre = Chapter.find_by_id(chapter_id)
      if @chapitre.nil?
        redirect_to root_path and return
      else
        @subject.chapter = @chapitre
      end
    end
    if @subject.save
      if !current_user.admin? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end
      flash[:success] = "Sujet ajouté."
      if @subject.chapter.nil? || @chapter.nil?
        redirect_to subject_path(@subject)
      else
        redirect_to chapter_subject_path(@subject.chapter, @subject)
      end
    else
      @preselect = params[:subject][:chapter_id].to_i
      render 'new'
    end
  end

  def update
    if !current_user.admin? && !params[:subject][:important].nil? # Hack
      redirect_to root_path
    end
    if @subject.update_attributes(params[:subject].except(:chapter_id))
      if @subject.user.admin? && !@subject.admin_user?
        @subject.admin_user = true
        @subject.save
      end
      chapter_id = params[:subject][:chapter_id].to_i
      if chapter_id != 0
        chapitre = Chapter.find_by_id(chapter_id)
        if chapitre.nil?
          redirect_to root_path and return
        else
          @subject.chapter = chapitre
          @subject.save
        end
      else
        @subject.chapter = nil
        @subject.save
      end
      
      if !current_user.admin? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end
      
      flash[:success] = "Sujet modifié."
      if @chapter.nil? || @subject.chapter.nil?
        redirect_to subject_path(@subject)
      else
        redirect_to chapter_subject_path(@subject.chapter, @subject)
      end
    else
      @preselect = params[:subject][:chapter_id].to_i
      render 'edit'
    end
  end
  
  def destroy
    @subject.delete
    @subject.messages.each do |m|
      m.destroy
    end
    flash[:success] = "Sujet supprimé."
    if @chapter.nil? || @subject.chapter.nil?
      redirect_to subjects_path
    else
      redirect_to chapter_subjects_path
    end
  end

  private

  def valid_chapter
    chapter_id = params[:chapter_id]
    if chapter_id.nil?
      @chapter = nil
    else
      @chapter = Chapter.find_by_id(chapter_id)
      redirect_to root_path if @chapter.nil?
    end
  end
  
  def online_chapter
    if @chapter.nil?
      return
    end
    redirect_to sections_path unless (current_user.admin? || @chapter.online)
  end
  
  def unlocked_chapter
    if @chapter.nil?
      return
    end
    if !current_user.admin?
      @chapter.prerequisites.each do |p|
        if (p.sections.count > 0 && !current_user.chapters.exists?(p))
          redirect_to sections_path and return
        end
      end
    end
  end

  def admin_user
    @subject = Subject.find(params[:id])
    redirect_to root_path unless (current_user.admin? || !@subject.admin)
  end
  
  def admin_delete
    redirect_to root_path unless current_user.admin?
  end

  def author
    @subject = Subject.find(params[:id])
    redirect_to subjects_path unless (current_user == @subject.user || (current_user.admin && !@subject.user.admin) || current_user.root)
  end
end

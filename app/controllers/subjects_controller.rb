#encoding: utf-8
class SubjectsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user
  before_filter :author, only: [:update, :edit]
  before_filter :valid_chapter

  def index
    if @chapter.nil?
      @subjects = Subject.order("lastcomment DESC").paginate(page: params[:page], per_page: 15)
    else
      @subjects = Subject.where(chapter_id: @chapview).order("lastcomment DESC").paginate(page: params[:page])
    end
  end

  def show
    @subject = Subject.find(params[:id])
    @messages = @subject.messages.order(:id).paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @subject = Subject.new
  end

  def edit
    @chap = @subject.chapter_id
  end

  def create
    @subject = Subject.create(params[:subject].except(:chapter_id))
    @subject.user = current_user
    @subject.lastcomment = DateTime.current
    chapter_id = params[:subject][:chapter_id]
    if chapter_id != 0
      @chapter = Chapter.find_by_id(chapter_id)
      if @chapter.nil?
        redirect_to root_path and return
      else
        @subject.chapter = @chapter
      end
    end
    if @subject.save
      flash[:success] = "Sujet ajouté."
      if @subject.chapter.nil?
        redirect_to subject_path(@subject)
      else
        redirect_to chapter_subject_path(@chapter, @subject)
      end
    else
      render 'new'
    end
  end

  def update
    if @subject.update_attributes(params[:subject])
      flash[:success] = "Sujet modifié."
      redirect_to subject_path(@subject)
    else
      render 'edit'
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

  def admin_user
    redirect_to root_path unless current_user.admin?
  end

  def author
    @subject = Subject.find(params[:id])
    redirect_to subjects_path unless current_user == @subject.user
  end
end

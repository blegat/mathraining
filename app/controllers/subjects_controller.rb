#encoding: utf-8
class SubjectsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user
  before_filter :author, only: [:update, :edit]

  def index
    if(params.has_key?:chapview)
      @chapview = params[:chapview]
      @subjects = Subject.where(:chapter_id => @chapview).order("lastcomment DESC").paginate(:page => params[:page])
    else
      @chapview = 0
      @subjects = Subject.order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15)
    end
  end
  
  def show
    @subject = Subject.find(params[:id])
    @messages = @subject.messages.order(:id).paginate(:page => params[:page], :per_page => 10)
  end

  def new
    @subject = Subject.new
    if(params.has_key?:chapview)
      @preselect = params[:chapview]
    else
      @preselect = 0
    end
  end

  def edit
    @chap = @subject.chapter_id
    @preselect = -1
  end

  def create
    @subject = Subject.create(params[:subject])
    @subject.user = current_user
    @subject.lastcomment = DateTime.current
    if @subject.save
      flash[:success] = "Sujet ajouté."
      redirect_to subject_path(@subject)
    else
      @preselect = -1
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

  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  
  def author
    @subject = Subject.find(params[:id])
    redirect_to subjects_path unless current_user == @subject.user
  end
end

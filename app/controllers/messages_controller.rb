#encoding: utf-8
class MessagesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user
  before_filter :author, only: [:update, :edit, :destroy]
  before_filter :valid_chapter

  def new
    @message = Message.new
    @subject = Subject.find(params[:subject_id])
  end

  def edit
  end

  def create
    @message = Message.create(params[:message])
    @subject = Subject.find(params[:subject_id])
    @message.user = current_user
    @message.subject = @subject
    if @message.save
      flash[:success] = "Message ajouté."

      @subject.lastcomment = DateTime.current
      @subject.save

      tot = @subject.messages.count
      page = [0,((tot-1)/10).floor].max + 1
      if @chapter.nil?
        redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page)
      else
        redirect_to chapter_subject_path(@chapter, @message.subject, :anchor => @message.id, :page => page)
      end
    else
      render 'new'
    end
  end

  def update
    if @message.update_attributes(params[:message])
      flash[:success] = "Message modifié."
      tot = @message.subject.messages.where("id <= ?", @message.id).count
      page = [0,((tot-1)/10).floor].max + 1
      if @chapter.nil?
        redirect_to subject_path(@message.subject, :anchor => @message.id, :page => page)
      else
        redirect_to chapter_subject_path(@chapter, @message.subject, :anchor => @message.id, :page => page)
      end
    else
      render 'edit'
    end
  end

  def destroy
    @message = Message.find(params[:id])
    @subject = @message.subject
    @message.destroy
    if @subject.messages.size > 0
      last = @subject.messages.order("id").last
      @subject.lastcomment = last.created_at
      @subject.save
    else
      @subject.lastcomment = @subject.created_at
      @subject.save
    end
    if @chapter.nil?
      redirect_to @subject
    else
      redirect_to chapter_subject_path(@chapter, @subject)
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
    @message = Message.find(params[:id])
    redirect_to subjects_path unless current_user == @message.user
  end
end

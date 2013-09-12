#encoding: utf-8
class MessagesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user, only: [:new, :create]
  before_filter :author, only: [:update, :edit, :destroy]
  before_filter :admin_delete, only: [:destroy]
  before_filter :valid_chapter
  before_filter :online_chapter
  before_filter :unlocked_chapter

  def new
    @message = Message.new
  end

  def edit
  end

  def create
    @message = Message.new(params[:message])
    @message.user = current_user.sk
    @message.subject = @subject
    @message.admin_user = current_user.sk.admin?
    
    attach = Array.new
    totalsize = 0
    
    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Messagefile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          flash[:error] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          render 'new' and return 
        end
        totalsize = totalsize + attach[i-1].file_file_size
        
        i = i+1
      end
      k = k+1
    end
    
    if totalsize > 10485760
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end

      flash[:error] = "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)"
      render 'new' and return
    end
    
    if @message.save
      j = 1
      while j < i do
        attach[j-1].message = @message
        attach[j-1].save
        j = j+1
      end
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
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      render 'new'
    end
  end

  def update
    if @message.update_attributes(params[:message])
      if @message.user.admin? && !@message.admin_user?
        @message.admin_user = true
        @message.save
      end
      
      totalsize = 0
      
      @message.messagefiles.each do |sf|
        if params["prevfile#{sf.id}".to_sym].nil?
          sf.file.destroy
          sf.destroy
        else
          totalsize = totalsize + sf.file_file_size
        end
      end
      
      attach = Array.new
    
      i = 1
      k = 1
      while !params["hidden#{k}".to_sym].nil? do
        if !params["file#{k}".to_sym].nil?
          attach.push()
          attach[i-1] = Messagefile.new(:file => params["file#{k}".to_sym])
          attach[i-1].message = @message
          if !attach[i-1].save
            j = 1
            while j < i do
              attach[j-1].file.destroy
              attach[j-1].destroy
              j = j+1
            end
            @message.reload
            nom = params["file#{k}".to_sym].original_filename
            flash[:error] = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
            render 'edit' and return 
          end
          totalsize = totalsize + attach[i-1].file_file_size
        
          i = i+1
        end
        k = k+1
      end
    
      if totalsize > 10485760
        j = 1
        while j < i do
          attach[j-1].file.destroy
          attach[j-1].destroy
          j = j+1
        end
        @message.reload
        flash[:error] = "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)"
        render 'edit' and return
      end
      
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
    
    @message.messagefiles.each do |f|
      f.file.destroy
      f.destroy
    end
    
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
  
  def online_chapter
    if @chapter.nil?
      return
    end
    redirect_to sections_path unless (current_user.sk.admin? || @chapter.online)
  end
  
  def unlocked_chapter
    if @chapter.nil?
      return
    end
    if !current_user.sk.admin?
      @chapter.prerequisites.each do |p|
        if (p.sections.count > 0 && !current_user.sk.chapters.exists?(p))
          redirect_to sections_path and return
        end
      end
    end
  end

  def admin_user
    @subject = Subject.find(params[:subject_id])
    redirect_to root_path unless (current_user.sk.admin? || !@subject.admin)
  end
  
  def admin_delete
    redirect_to root_path unless current_user.sk.admin?
  end

  def author
    @message = Message.find(params[:id])
    redirect_to subjects_path unless (current_user.sk == @message.user || (current_user.sk.admin && !@message.user.admin) || current_user.sk.root)
  end
end

#encoding: utf-8
class SubjectsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :migrate]
  before_action :admin_subject_user, only: [:show]
  before_action :author, only: [:update, :destroy]
  before_action :admin_user, only: [:destroy, :migrate]
  before_action :notskin_user, only: [:create, :update]
  before_action :get_q, only: [:create, :update, :destroy, :migrate]
  
  # Voir tous les sujets
  def index
    cherche_category = -1
    cherche_section = -1
    cherche_chapitre = -1
    cherche_personne = false
    q = -1

    @category = nil
    @chapitre = nil
    @section = nil
    if(params.has_key?:q)
      q = params[:q].to_i
      if q > 999999
        cherche_category = q/1000000
        @category = Category.find(cherche_category)
      elsif q > 999
        cherche_section = q/1000
        @section = Section.find(cherche_section)
      elsif q > 0
        cherche_chapitre = q
        @chapitre = Chapter.find(cherche_chapitre)
        @section = @chapitre.section
      else
        cherche_personne = true
      end
    else
      cherche_personne = true
      q = 0
    end

    @importants = Array.new
    Subject.includes(:user, :category, :section, :chapter).where(important: true).order("lastcomment DESC").to_a.each do |s|
      if ((signed_in? && (current_user.sk.admin? || current_user.sk.corrector?)) || !s.admin) && (!s.wepion || (signed_in? && (current_user.sk.admin? || current_user.sk.wepion)))
        if cherche_personne || (cherche_category >= 0 && !s.category.nil? && s.category.id == cherche_category) || (cherche_section >= 0 && !s.section.nil? && s.section.id == cherche_section) || (cherche_chapitre >= 0 && !s.chapter.nil? && s.chapter.id == cherche_chapitre)
          @importants.push(s)
        end
      end
    end

    @subjects = Array.new
    Subject.includes(:user, :category, :section, :chapter).where(important: false).order("lastcomment DESC").to_a.each do |s|
      if ((signed_in? && (current_user.sk.admin? || current_user.sk.corrector?)) || !s.admin) && (!s.wepion || (signed_in? && (current_user.sk.admin? || current_user.sk.wepion)))
        if cherche_personne || (cherche_category >= 0 && !s.category.nil? && s.category.id == cherche_category) || (cherche_section >= 0 && !s.section.nil? && s.section.id == cherche_section) || (cherche_chapitre >= 0 && !s.chapter.nil? && s.chapter.id == cherche_chapitre)
          @subjects.push(s)
        end
      end
    end

    @subjectsfalse = @subjects.paginate(:page => params[:page], :per_page => 15)
  end

  # Montre un sujet
  def show
    @messages = @subject.messages.order(:id).paginate(:page => params[:page], :per_page => 10)
  end

  # Créer un sujet
  def new
    @subject = Subject.new
  end

  # Créer un sujet 2
  def create
    if !current_user.sk.admin? && !params[:subject][:important].nil? # Hack
      redirect_to root_path and return
    end
    
    params[:subject][:title] = truncate(params[:subject][:title])
    params[:subject][:content] = truncate(params[:subject][:content])
    @subject = Subject.new(params.require(:subject).permit(:title, :content, :admin, :important, :wepion))
    @subject.user = current_user.sk
    @subject.lastcomment = DateTime.current

    if @subject.admin
      @subject.wepion = false # On n'autorise pas wépion si admin
    end

    if @subject.title.size > 0
      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)
    end

    category_id = params[:subject][:category_id].to_i
    if category_id < 1000
      @subject.category = Category.find(category_id)
      @subject.section = nil
      @subject.chapter = nil
      @subject.exercise = nil
      @subject.qcm = nil
    else
      section_id = category_id/1000
      @subject.category = nil
      @subject.section = Section.find(section_id)
      chapter_id = params[:subject][:chapter_id].to_i
      if chapter_id == 0
        @subject.chapter = nil
        @subject.exercise = nil
        @subject.qcm = nil
      else
        @subject.chapter = Chapter.find(chapter_id)
        exercise_id = params[:subject][:exercise_id].to_i
        if exercise_id == 0
          @subject.exercise = nil
          @subject.qcm = nil
        else
          type = exercise_id / 1000
          exercise_id = exercise_id % 1000
          if type == 2
            @subject.exercise = Exercise.find(exercise_id)
            @subject.qcm = nil
          else
            @subject.qcm = Qcm.find(exercise_id)
            @subject.exercise = nil
          end
        end
      end
    end

    # Pièces jointes
    @error = false
    @error_message = ""

    attach = create_files # Fonction commune pour toutes les pièces jointes

    if @error
      error_create([@error_message]) and return
    end

    # Si on parvient à enregistrer
    if @subject.save
      j = 1
      while j < attach.size()+1 do
        attach[j-1].update_attribute(:myfiletable, @subject)
        j = j+1
      end
      if !current_user.sk.admin? && !current_user.sk.corrector? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end

      if current_user.sk.admin?
        for g in ["A", "B"] do
          if params.has_key?("groupe" + g)
            User.where(:group => g).each do |u|
              UserMailer.new_message_group(u.id, @subject.id, current_user.sk.name, 0).deliver if Rails.env.production?
            end
          end
        end
      end

      flash[:success] = "Votre sujet a bien été posté."

      redirect_to subject_path(@subject, :q => @q)

      # Si il y a eu une erreur
    else
      destroy_files(attach, attach.size()+1)
      error_create(@subject.errors.full_messages) and return
    end
  end

  # Editer un sujet 2
  def update
    if !current_user.sk.admin? && !current_user.sk.corrector? && !params[:subject][:important].nil? # Hack
      redirect_to root_path
    end

    params[:subject][:title] = truncate(params[:subject][:title])
    params[:subject][:content] = truncate(params[:subject][:content])
    if @subject.update_attributes(params.require(:subject).permit(:title, :content, :admin, :important, :wepion))

      if @subject.admin
        @subject.wepion = false # On n'autorise pas wépion si admin
        @subject.save
      end

      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)

      category_id = params[:subject][:category_id].to_i
      if category_id < 1000
        @subject.category = Category.find(category_id)
        @subject.section = nil
        @subject.chapter = nil
        @subject.exercise = nil
        @subject.qcm = nil
      else
        section_id = category_id/1000
        @subject.category = nil
        @subject.section = Section.find(section_id)
        chapter_id = params[:subject][:chapter_id].to_i
        if chapter_id == 0
          @subject.chapter = nil
          @subject.exercise = nil
          @subject.qcm = nil
        else
          @subject.chapter = Chapter.find(chapter_id)
          exercise_id = params[:subject][:exercise_id].to_i
          if exercise_id == 0
            @subject.exercise = nil
            @subject.qcm = nil
          else
            type = exercise_id / 1000
            exercise_id = exercise_id % 1000
            if type == 2
              @subject.exercise = Exercise.find(exercise_id)
              @subject.qcm = nil
            else
              @subject.qcm = Qcm.find(exercise_id)
              @subject.exercise = nil
            end
          end
        end
      end

      @subject.save

      if !current_user.sk.admin? && !current_user.sk.corrector? && @subject.admin? # Hack
        @subject.admin = false
        @subject.save
      end

      # Pièces jointes
      @error = false
      @error_message = ""

      attach = update_files(@subject, "Subject") # Fonction commune pour toutes les pièces jointes

      if @error
        error_update([@error_message]) and return
      end
      flash[:success] = "Votre sujet a bien été modifié."
      session["successSubject"] = "ok"
      redirect_to subject_path(@subject, :q => @q)
    else
      error_update(@subject.errors.full_messages) and return
    end
  end

  # Supprimer un sujet : il faut être admin
  def destroy
    @subject.myfiles.each do |f|
      f.file.destroy
      f.destroy
    end
    @subject.fakefiles.each do |f|
      f.destroy
    end
    @subject.messages.each do |m|
      m.myfiles.each do |f|
        f.file.destroy
        f.destroy
      end
      m.fakefiles.each do |f|
        f.destroy
      end
      m.destroy
    end
    @subject.followingsubjects.each do |f|
      f.destroy
    end
    @subject.destroy
    flash[:success] = "Sujet supprimé."

    redirect_to subjects_path(:q => @q)
  end

  # Migrer un sujet vers un autre : il faut être root (disons admin)
  def migrate
    @subject = Subject.find(params[:subject_id])
    autre_id = params[:migreur].to_i
    @migreur = Subject.find(autre_id)

    premier_message = Message.new(content: @subject.content + "\n\n[i][u]Remarque[/u] : Ce message faisait partie d'un autre sujet appelé '#{@subject.title}' et a été migré ici par un administrateur.[/i]", created_at: @subject.created_at)
    premier_message.user = @subject.user
    premier_message.subject = @migreur
    premier_message.save

    @subject.messages.order(:id).each do |m|
      newm = Message.new(content: m.content, created_at: m.created_at)
      newm.user = m.user
      newm.subject = @migreur
      newm.save
      m.delete
    end

    @migreur.lastcomment = [@migreur.lastcomment, @subject.lastcomment].max
    @migreur.save

    @subject.delete

    redirect_to subject_path(@migreur, :q => @q)
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def error_create(err)
    session["errorSubject"] = err
    session[:oldAll] = params[:subject]
    redirect_to new_subject_path(:q => @q)
  end
  
  def error_update(err)
    session["errorSubject"] = err
    session[:oldAll] = params[:subject]
    redirect_to subject_path(@subject, :q => @q)
  end
  
  def get_q
    @q = 0
    @q = params[:q].to_i if params.has_key?:q
  end

  def admin_subject_user
    @subject = Subject.find(params[:id])
    redirect_to root_path unless ((signed_in? && (current_user.sk.admin? || current_user.sk.corrector?)) || !@subject.admin)
  end

  def author
    @subject = Subject.find(params[:id])
    redirect_to subjects_path unless (current_user.sk == @subject.user || (current_user.sk.admin && !@subject.user.admin) || current_user.sk.root)
  end
end

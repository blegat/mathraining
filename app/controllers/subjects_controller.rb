#encoding: utf-8
class SubjectsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :migrate]
  before_action :get_subject, only: [:show, :update, :destroy]
  before_action :admin_subject_user, only: [:show]
  before_action :author, only: [:update, :destroy]
  before_action :admin_user, only: [:destroy, :migrate]
  before_action :notskin_user, only: [:create, :update]
  before_action :get_q, only: [:create, :update, :destroy, :migrate]
  
  # Voir tous les sujets
  def index
    cherche_category = -1
    cherche_section = -1
    cherche_section_problems = -1
    cherche_chapitre = -1
    cherche_personne = false
    q = -1

    @category = nil
    @chapitre = nil
    @section = nil
    if(params.has_key?:q)
      q = params[:q].to_i
      if q >= 1000000
        cherche_category = q/1000000
        @category = Category.find_by_id(cherche_category)
        if @category.nil?
          render 'errors/access_refused' and return
        end
      elsif q >= 1000
        if q % 1000 == 0
          cherche_section = q/1000
          @section = Section.find_by_id(cherche_section)
        elsif q % 1000 == 1
          cherche_section_problems = (q-1)/1000
          @section = Section.find_by_id(cherche_section_problems)
        end
        if @section.nil?
          render 'errors/access_refused' and return
        end
      elsif q > 0
        cherche_chapitre = q
        @chapitre = Chapter.find_by_id(cherche_chapitre)
        if @chapitre.nil? || !@chapitre.online?
          render 'errors/access_refused' and return
        end
        @section = @chapitre.section
      else
        cherche_personne = true
      end
    else
      cherche_personne = true
      q = 0
    end
    
    if (current_user.sk.admin? || current_user.sk.corrector?)
      admin_allowed_values = [false, true]
    else
      admin_allowed_values = false
    end
    
    if (current_user.sk.admin? || current_user.sk.wepion?)
      wepion_allowed_values = [false, true]
    else
      wepion_allowed_values = false
    end
    
    if cherche_personne
      @importants = Subject.where(important: true,  admin: admin_allowed_values, wepion: wepion_allowed_values).order("lastcomment DESC").includes(:user, :lastcomment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, admin: admin_allowed_values, wepion: wepion_allowed_values).order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :lastcomment_user, :category, :section, :chapter)
    elsif cherche_category >= 0
      @importants = Subject.where(important: true,  admin: admin_allowed_values, wepion: wepion_allowed_values, category: cherche_category).order("lastcomment DESC").includes(:user, :lastcomment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, admin: admin_allowed_values, wepion: wepion_allowed_values, category: cherche_category).order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :lastcomment_user, :category, :section, :chapter)
    elsif cherche_section >= 0
      @importants = Subject.where(important: true,  admin: admin_allowed_values, wepion: wepion_allowed_values, section: cherche_section).order("lastcomment DESC").includes(:user, :lastcomment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, admin: admin_allowed_values, wepion: wepion_allowed_values, section: cherche_section).order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :lastcomment_user, :category, :section, :chapter)
    elsif cherche_section_problems >= 0
      @importants = Subject.where(important: true,  admin: admin_allowed_values, wepion: wepion_allowed_values, section: cherche_section_problems).where.not(problem_id: nil).order("lastcomment DESC").includes(:user, :lastcomment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, admin: admin_allowed_values, wepion: wepion_allowed_values, section: cherche_section_problems).where.not(problem_id: nil).order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :lastcomment_user, :category, :section, :chapter)
    elsif cherche_chapitre
      @importants = Subject.where(important: true,  admin: admin_allowed_values, wepion: wepion_allowed_values, chapter: cherche_chapitre).order("lastcomment DESC").includes(:user, :lastcomment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, admin: admin_allowed_values, wepion: wepion_allowed_values, chapter: cherche_chapitre).order("lastcomment DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :lastcomment_user, :category, :section, :chapter)
    end
  end

  # Montre un sujet
  def show
    @messages = @subject.messages.order(:created_at).paginate(:page => params[:page], :per_page => 10)
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
    
    params[:subject][:title].strip! if !params[:subject][:title].nil?
    params[:subject][:content].strip! if !params[:subject][:content].nil?
    @subject = Subject.new(params.require(:subject).permit(:title, :content, :admin, :important, :wepion))
    @subject.user = current_user.sk
    @subject.lastcomment = DateTime.current
    @subject.lastcomment_user = current_user.sk

    if @subject.admin
      @subject.wepion = false # On n'autorise pas wépion si admin
    end

    if @subject.title.size > 0
      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)
    end

    category_id = params[:subject][:category_id].to_i
    if category_id < 1000
      @subject.category = Category.find_by_id(category_id)
      if @subject.category.nil?
        render 'errors/access_refused' and return
      end
      @subject.section = nil
      @subject.chapter = nil
      @subject.question = nil
      @subject.problem = nil
    else
      section_id = category_id/1000
      @subject.category = nil
      @subject.section = Section.find_by_id(section_id)
      if @subject.section.nil?
        render 'errors/access_refused' and return
      end
      chapter_id = params[:subject][:chapter_id].to_i
      if chapter_id == 0
        @subject.chapter = nil
        @subject.question = nil
        @subject.problem = nil
      elsif chapter_id == -1
        @subject.chapter = nil
        @subject.question = nil
        problem_id = params[:subject][:problem_id].to_i
        if problem_id == 0
          error_create(["Un problème doit être sélectionné."]) and return
        end
        @subject.problem = Problem.find_by_id(problem_id)
        if @subject.problem.nil? # Here we can check that the user has indeed access to the problem but it is annoying to do
          render 'errors/access_refused' and return
        end
      else
        @subject.chapter = Chapter.find_by_id(chapter_id)
        if @subject.chapter.nil? || !@subject.chapter.online
          render 'errors/access_refused' and return
        end
        @subject.problem = nil
        question_id = params[:subject][:question_id].to_i
        if question_id == 0
          @subject.question = nil
        else
          @subject.question = Question.find_by_id(question_id)
          if @subject.question.nil? # Here we can check that the user has indeed access to the question but it is annoying to do
            render 'errors/access_refused' and return
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
              UserMailer.new_message_group(u.id, @subject.id, current_user.sk.id).deliver if Rails.env.production?
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
    
    params[:subject][:title].strip! if !params[:subject][:title].nil?
    params[:subject][:content].strip! if !params[:subject][:content].nil?
    @subject.title = params[:subject][:title]
    @subject.content = params[:subject][:content]
    @subject.admin = params[:subject][:admin] if !params[:subject][:admin].nil?
    @subject.important = params[:subject][:important] if !params[:subject][:important].nil?
    @subject.wepion = params[:subject][:wepion] if !params[:subject][:wepion].nil?
    if @subject.valid?

      if @subject.admin
        @subject.wepion = false # On n'autorise pas wépion si admin
      end

      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)

      category_id = params[:subject][:category_id].to_i
      if category_id < 1000
        @subject.category = Category.find_by_id(category_id)
        if @subject.category.nil?
          render 'errors/access_refused' and return
        end
        @subject.section = nil
        @subject.chapter = nil
        @subject.question = nil
        @subject.problem = nil
      else
        section_id = category_id/1000
        @subject.category = nil
        @subject.section = Section.find_by_id(section_id)
        if @subject.section.nil?
          render 'errors/access_refused' and return
        end
        chapter_id = params[:subject][:chapter_id].to_i
        if chapter_id == 0
          @subject.chapter = nil
          @subject.question = nil
          @subject.problem = nil
        elsif chapter_id == -1
          @subject.chapter = nil
          @subject.question = nil
          problem_id = params[:subject][:problem_id].to_i
          if problem_id == 0
            error_update(["Un problème doit être sélectionné."]) and return
          end
          @subject.problem = Problem.find_by_id(problem_id)
          if @subject.problem.nil? # Here we can check that the user has indeed access to the problem but it is annoying to do
            render 'errors/access_refused' and return
          end
        else
          @subject.chapter = Chapter.find_by_id(chapter_id)
          if @subject.chapter.nil?
            render 'errors/access_refused' and return
          end
          @subject.problem = nil
          question_id = params[:subject][:question_id].to_i
          if question_id == 0
            @subject.question = nil
          else
            @subject.question = Question.find_by_id(question_id)
            if @subject.question.nil? # Here we can check that the user has indeed access to the question but it is annoying to do
              render 'errors/access_refused' and return
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

      attach = update_files(@subject) # Fonction commune pour toutes les pièces jointes

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

  # Migrer un sujet vers un autre : il faut être root
  def migrate
    @subject = Subject.find_by_id(params[:subject_id])
    if @subject.nil?
      render 'errors/access_refused' and return
    end
    autre_id = params[:migreur].to_i
    @migreur = Subject.find_by_id(autre_id)
    
    if @migreur.nil?
      flash[:danger] = "Ce sujet n'existe pas."
      redirect_to @subject and return
    end

    if @migreur.created_at > @subject.created_at
      flash[:danger] = "Le sujet le plus récent doit être migré vers le sujet le moins récent."
      redirect_to @subject and return
    end
    
    premier_message = Message.new(content: @subject.content + "\n\n[i][u]Remarque[/u] : Ce message faisait partie d'un autre sujet appelé '#{@subject.title}' et a été migré ici par un administrateur.[/i]", created_at: @subject.created_at)
    premier_message.user = @subject.user
    premier_message.subject = @migreur
    premier_message.save

    @subject.messages.each do |m|
      m.subject = @migreur
      m.save
    end

    if @subject.lastcomment > @migreur.lastcomment
      @migreur.lastcomment = @subject.lastcomment
      @migreur.lastcomment_user_id = @subject.lastcomment_user_id
      @migreur.save
    end

    @subject.delete

    redirect_to subject_path(@migreur, :q => @q)
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def error_create(err)
    session["errorSubject"] = err
    session[:oldAll] = params[:subject]
    redirect_to new_subject_path(:q => @q) and return true
  end
  
  def error_update(err)
    session["errorSubject"] = err
    session[:oldAll] = params[:subject]
    redirect_to subject_path(@subject, :q => @q) and return true
  end
  
  def get_subject
    @subject = Subject.find_by_id(params[:id])
    if @subject.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_q
    @q = 0
    @q = params[:q].to_i if params.has_key?:q
  end

  def admin_subject_user
    unless ((@signed_in && (current_user.sk.admin? || current_user.sk.corrector?)) || !@subject.admin)
      render 'errors/access_refused' and return
    end
  end

  def author
    unless (current_user.sk == @subject.user || (current_user.sk.admin && !@subject.user.admin) || current_user.sk.root)
      render 'errors/access_refused' and return
    end
  end
end

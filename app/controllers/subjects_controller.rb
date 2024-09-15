#encoding: utf-8
class SubjectsController < ApplicationController
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user, only: [:index, :show, :new, :unfollow]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :migrate, :follow]
  before_action :admin_user, only: [:destroy, :migrate]
  before_action :notskin_user, only: [:create, :update]
  
  before_action :get_subject, only: [:show, :update, :destroy]
  before_action :get_subject2, only: [:migrate, :follow, :unfollow]
  
  before_action :user_that_can_see_subject, only: [:show, :follow]
  before_action :user_that_can_update_subject, only: [:update, :destroy]
  
  
  before_action :get_q, only: [:index, :show, :new, :create, :update, :destroy, :migrate]
  
  # Show the list of (recent) subjects
  def index
    search_category = -1
    search_section = -1
    search_section_problems = -1
    search_chapter = -1

    @category = nil
    @chapter = nil
    @section = nil
    @title_complement = ""
    if !@q.nil? && @q.size >= 5 # NB: @q is never equal to "all", see get_q
      what = @q.slice(0..2)
      id = @q.slice(4..-1).to_i
      if what == "cat"
        @category = Category.find_by_id(id)
        if !@category.nil? && (@category.name != "Wépion" || current_user.sk.wepion? || current_user.sk.admin?)
          search_category = id
          @title_complement = @category.name
        end
      elsif what == "sec"
        @section = Section.find_by_id(id)
        if !@section.nil?
          search_section = id
          @title_complement = @section.name
        end
      elsif what == "pro"
        @section = Section.find_by_id(id)
        if !@section.nil?
          search_section_problems = id
          @title_complement = helpers.get_problem_category_name(@section.name)
        end
      elsif what == "cha"
        @chapter = Chapter.find_by_id(id)
        if !@chapter.nil? && @chapter.online
          search_chapter = id
          @section = @chapter.section
          @title_complement = @chapter.name
        end
      end
    end
    
    if (current_user.sk.admin? || current_user.sk.corrector?)
      correctors_allowed_values = [false, true]
    else
      correctors_allowed_values = false
    end
    
    if (current_user.sk.admin? || current_user.sk.wepion?)
      wepion_allowed_values = [false, true]
    else
      wepion_allowed_values = false
    end
    
    if search_category >= 0
      @importants = Subject.where(important: true,  for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, category: search_category).order("last_comment_time DESC").includes(:user, :last_comment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, category: search_category).order("last_comment_time DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :last_comment_user, :category, :section, :chapter)
    elsif search_section >= 0
      @importants = Subject.where(important: true,  for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, section: search_section).order("last_comment_time DESC").includes(:user, :last_comment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, section: search_section).order("last_comment_time DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :last_comment_user, :category, :section, :chapter)
    elsif search_section_problems >= 0
      @importants = Subject.where(important: true,  for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, section: search_section_problems).where.not(problem_id: nil).order("last_comment_time DESC").includes(:user, :last_comment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, section: search_section_problems).where.not(problem_id: nil).order("last_comment_time DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :last_comment_user, :category, :section, :chapter)
    elsif search_chapter >= 0
      @importants = Subject.where(important: true,  for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, chapter: search_chapter).order("last_comment_time DESC").includes(:user, :last_comment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values, chapter: search_chapter).order("last_comment_time DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :last_comment_user, :category, :section, :chapter)
    else # Search nothing
      @importants = Subject.where(important: true,  for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values).order("last_comment_time DESC").includes(:user, :last_comment_user, :category, :section, :chapter)
      @subjects   = Subject.where(important: false, for_correctors: correctors_allowed_values, for_wepion: wepion_allowed_values).order("last_comment_time DESC").paginate(:page => params[:page], :per_page => 15).includes(:user, :last_comment_user, :category, :section, :chapter)
    end
  end

  # Show one subject
  def show
    @page = params[:page].to_i if params.has_key?(:page)
    # @messages is computed in the view to be able to render subjects/show in case of error
  end

  # Create a subject (show form)
  def new
    @subject = Subject.new
  end

  # Create a subject (send form)
  def create    
    params[:subject][:title].strip! if !params[:subject][:title].nil?
    params[:subject][:content].strip! if !params[:subject][:content].nil?
    allowed_params = [:title, :content]
    allowed_params << :for_correctors if (current_user.sk.corrector? || current_user.sk.admin?)
    allowed_params << :important if current_user.sk.admin?
    allowed_params << :for_wepion if (current_user.sk.wepion? || current_user.sk.admin?)
    @subject = Subject.new(params.require(:subject).permit(allowed_params))
    @subject.user = current_user.sk
    @subject.last_comment_time = DateTime.now
    @subject.last_comment_user = current_user.sk
    
    @subject.for_wepion = false if @subject.for_correctors # We don't allow Wépion if for correctors

    if @subject.title.size > 0
      @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)
    end
    
    # Invalid CSRF token
    error_create([get_csrf_error_message]) and return if @invalid_csrf_token

    # Set associated object (category, section, chapter, exercise, problem)
    err = set_associated_object
    error_create([err]) and return if !err.empty?
    
    # Invalid subject
    error_create(@subject.errors.full_messages) and return if !@subject.valid?

    # Attached files
    attach = create_files
    error_create([@file_error]) and return if !@file_error.nil?

    @subject.save
    
    attach_files(attach, @subject)

    if current_user.sk.root?
      if params.has_key?("emailWepion")
        User.where(:group => ["A", "B"]).each do |u|
          UserMailer.new_message_group(u.id, @subject.id, current_user.sk.id).deliver
        end
      end
    end

    flash[:success] = "Votre sujet a bien été posté."
    redirect_to subject_path(@subject, :q => @q)
  end

  # Update a subject (send the form)
  def update    
    params[:subject][:title].strip! if !params[:subject][:title].nil?
    params[:subject][:content].strip! if !params[:subject][:content].nil?
    @subject.title = params[:subject][:title]
    @subject.title = @subject.title.slice(0,1).capitalize + @subject.title.slice(1..-1)
    @subject.content = params[:subject][:content]
    @subject.for_correctors = params[:subject][:for_correctors] if !params[:subject][:for_correctors].nil? && (current_user.sk.corrector? || current_user.sk.admin?)
    @subject.important = params[:subject][:important] if !params[:subject][:important].nil? && current_user.sk.admin?
    @subject.for_wepion = params[:subject][:for_wepion] if !params[:subject][:for_wepion].nil? && (current_user.sk.wepion? || current_user.sk.admin?)
    
    @subject.for_wepion = false if @subject.for_correctors # We don't allow Wépion if for correctors
    
    # Invalid CSRF token
    error_update([get_csrf_error_message]) and return if @invalid_csrf_token
    
    # Invalid subject
    error_update(@subject.errors.full_messages) and return if !@subject.valid?
    
    # Set associated object (category, section, chapter, exercise, problem)
    err = set_associated_object
    error_update([err]) and return if !err.empty?

    # Attached files
    update_files(@subject)
    error_update([@file_error]) and return if !@file_error.nil?
      
    @subject.save
    
    flash[:success] = "Votre sujet a bien été modifié."
    redirect_to subject_path(@subject, :q => @q, :msg => 0)
  end

  # Delete a subject
  def destroy
    @subject.destroy
    flash[:success] = "Sujet supprimé."
    redirect_to subjects_path(:q => @q)
  end

  # Migrate a subject to another one
  def migrate    
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
    
    premier_message = Message.create(:content    => @subject.content + "\n\n[i][u]Remarque[/u] : Ce message faisait partie d'un autre sujet appelé '#{@subject.title}' et a été migré ici par un administrateur.[/i]",
                                     :created_at => @subject.created_at,
                                     :user       => @subject.user,
                                     :subject    => @migreur)

    @subject.myfiles.each do |f|
      f.update_attribute(:myfiletable, premier_message)
    end

    @subject.fakefiles.each do |f|
      f.update_attribute(:fakefiletable, premier_message)
    end

    @subject.messages.each do |m|
      m.update_attribute(:subject, @migreur)
    end

    if @subject.last_comment_time > @migreur.last_comment_time
      @migreur.update(:last_comment_time    => @subject.last_comment_time,
                      :last_comment_user_id => @subject.last_comment_user_id)
    end

    @subject.reload # Important because otherwise the "destroy" below also destroys the old messages and files of the subject
    @subject.destroy

    redirect_to subject_path(@migreur, :q => @q)
  end
  
  # Follow the subject (to receive emails)
  def follow
    current_user.sk.followed_subjects << @subject unless current_user.sk.followed_subjects.exists?(@subject.id)
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque fois qu'un nouveau message sera posté sur ce sujet."
    redirect_back(fallback_location: subject_path(@subject))
  end
  
  # Unfollow the subject (to stop receiving emails)
  def unfollow
    current_user.sk.followed_subjects.destroy(@subject)
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce sujet."
    redirect_back(fallback_location: subject_path(@subject))
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the subject
  def get_subject
    @subject = Subject.find_by_id(params[:id])
    return if check_nil_object(@subject)
  end
  
  # Get the subject (v2)
  def get_subject2
    @subject = Subject.find_by_id(params[:subject_id])
    return if check_nil_object(@subject)
  end
  
  # Get the "q" value that is used through the forum
  def get_q
    @q = params[:q] if params.has_key?:q
    @q = nil if @q == "all" # avoid q = "all" when there is no filter
  end
  
  ########## CHECK METHODS ##########

  # Check that current user can update the subject
  def user_that_can_update_subject
    unless @subject.can_be_updated_by(current_user.sk)
      render 'errors/access_refused' and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to set the object associated to a subject
  def set_associated_object
    cat = params[:subject][:category_id].to_i
    if cat >= 0 # Category
      @subject.category = Category.find_by_id(cat)
      return "Une erreur est survenue." if @subject.category.nil?
      @subject.section = nil
      @subject.chapter = nil
      @subject.question = nil
      @subject.problem = nil
    else # Section
      @subject.category = nil
      @subject.section = Section.find_by_id(-cat)
      return "Une erreur est survenue." if @subject.section.nil?
      chapter_id = params[:subject][:chapter_id].to_i
      if chapter_id == 0 # No particular chapter
        @subject.chapter = nil
        @subject.question = nil
        @subject.problem = nil
      elsif chapter_id == -1 # Problems of this section
        @subject.chapter = nil
        @subject.question = nil
        problem_id = params[:subject][:problem_id].to_i
        if problem_id == 0
          return "Un problème doit être sélectionné."
        end
        @subject.problem = Problem.find_by_id(problem_id)
        return "Une erreur est survenue." if @subject.problem.nil? || !@subject.problem.online?
        # Here we can check that the user has indeed access to the problem but it is annoying to do
      else
        @subject.chapter = Chapter.find_by_id(chapter_id)
        return "Une erreur est survenue." if @subject.chapter.nil? || !@subject.chapter.online?
        @subject.problem = nil
        question_id = params[:subject][:question_id].to_i
        if question_id == 0
          @subject.question = nil
        else
          @subject.question = Question.find_by_id(question_id)
          return "Une erreur est survenue." if @subject.question.nil? || !@subject.question.online?
          # Here we can check that the user has indeed access to the question but it is annoying to do
        end
      end
    end
    
    return "" # Return empty string when no error
  end
  
  # Helper method when an error occurred during create
  def error_create(err)
    @error_case = "errorSubject"
    @error_msgs = err
    @error_params = params[:subject]
    render 'new'
  end
  
  # Helper method when an error occurred during update
  def error_update(err)
    @error_case = "errorSubject"
    @error_msgs = err
    @error_params = params[:subject]
    render 'show'
  end
end

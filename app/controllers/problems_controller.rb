#encoding: utf-8
class ProblemsController < QuestionsController
  before_filter :signed_in_user, only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online, :explanation, :update_explanation, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_filter :admin_user, only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online, :explanation, :update_explanation, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_filter :root_problem_user, only: [:destroy]
  before_filter :has_access, only: [:show]
  before_filter :online_problem, only: [:show]
  before_filter :can_be_online, only: [:put_online]
  before_filter :enough_points, only: [:show]

  # Voir le problème : il faut avoir accès
  def show
  end

  # Créer un problème : il faut être admin
  def new
    @problem = Problem.new
    @section = Section.find(params[:section_id])
  end

  # Editer un problème : il faut être admin
  def edit
    @problem = Problem.find(params[:id])
  end

  # Créer un problème 2 : il faut être admin
  def create
    @problem = Problem.new
    @problem.statement = params[:problem][:statement]
    @problem.origin = params[:problem][:origin]
    @problem.level = params[:problem][:level]
    @section = Section.find_by_id(params[:section_id])
    @problem.online = false
    @problem.section = @section

    nombre = 0
    loop do
      nombre = @problem.level*100 + @problem.section.id*1000+rand(100)
      break if Problem.where(:number => nombre).count == 0
    end
    @problem.number = nombre

    @problem.explanation = ""
    if @problem.save
      flash[:success] = "Problème ajouté."
      redirect_to problem_path(@problem)
    else
      render 'new'
    end
  end

  # Editer un problème 2 : il faut être admin
  def update
    @problem = Problem.find(params[:id])
    @problem.statement = params[:problem][:statement]
    @problem.origin = params[:problem][:origin]

    if !@problem.online
      if @problem.level != params[:problem][:level].to_i
        @problem.level = params[:problem][:level]
        nombre = 0
        loop do
          nombre = @problem.level*100 + @problem.section.id*1000+rand(100)
          break if Problem.where(number: nombre).count == 0
        end
        @problem.number = nombre
      end
    end
    if @problem.save
      flash[:success] = "Problème modifié."
      redirect_to problem_path(@problem)
    else
      render 'edit'
    end
  end

  # Supprimer un problème : il faut être admin, voire root
  def destroy
    @section = @problem.section

    @problem.submissions.each do |s|
      s.submissionfiles.each do |f|
        f.file.destroy
        f.destroy
      end
      s.corrections.each do |c|
        c.correctionfiles.each do |f|
          f.file.destroy
          f.destroy
        end
        c.destroy
      end
      s.destroy
    end

    if @problem.online
      @problem.destroy
      User.all.each do |user|
        point_attribution(user)
      end
    else
      @problem.destroy
    end
    flash[:success] = "Problème supprimé."
    redirect_to pb_sections_path(@section)
  end

  # Mettre un problème en ligne : il faut qu'il puisse l'être
  def put_online
    @problem.online = true
    @problem.save
    @section = @problem.section
    @section.max_score = @section.max_score + @problem.value
    @section.save
    redirect_to problem_path(@problem)
  end

  # Modifier l'explication d'un problème
  def explanation
    @problem = Problem.find(params[:problem_id])
  end

  # Modifier l'explication d'un problème 2
  def update_explanation
    @problem = Problem.find(params[:problem_id])
    @problem.explanation = params[:problem][:explanation]
    if @problem.save
      flash[:success] = "Solution officielle modifiée."
      redirect_to problem_path(@problem)
    else
      render 'explanation'
    end
  end

  # Supprimer un prérequis
  def delete_prerequisite
    @chapter = Chapter.find(params[:chapter_id])
    @problem = Problem.find(params[:problem_id])
    @problem.chapters.delete(@chapter)
    redirect_to @problem
  end

  # Ajouter un prérequis
  def add_prerequisite
    @problem = Problem.find(params[:problem_id])
    if !params[:chapter_problem][:chapter_id].empty?
      @chapter = Chapter.find(params[:chapter_problem][:chapter_id])
      @problem.chapters << @chapter
    end
    redirect_to @problem
  end

  # Ajouter à un test virtuel
  def add_virtualtest
    @problem = Problem.find(params[:problem_id])
    if !params[:problem][:virtualtest_id].empty?
      if params[:problem][:virtualtest_id].to_i == 0
        @problem.virtualtest_id = 0
      else
        @t = Virtualtest.find(params[:problem][:virtualtest_id].to_i)
        lastnumero = @t.problems.order(:position).reverse_order.first
        if lastnumero.nil?
          @problem.position = 1
        else
          @problem.position = lastnumero.position+1
        end
        @problem.virtualtest = @t
      end
      @problem.save
    end
    redirect_to @problem
  end

  # Déplacer dans un test virtuel
  def order_minus
    @problem = Problem.find(params[:problem_id])
    @t = @problem.virtualtest
    @problem2 = @t.problems.where("position < ?", @problem.position).order('position').reverse_order.first
    swap_position(@problem, @problem2)
    flash[:success] = "Problème déplacé vers la droite."
    redirect_to virtualtest_path(@t, :p => @problem.id)
  end

  # Déplacer dans un test virtuel
  def order_plus
    @problem = Problem.find(params[:problem_id])
    @t = @problem.virtualtest
    @problem2 = @t.problems.where("position > ?", @problem.position).order('position').first
    swap_position(@problem, @problem2)
    flash[:success] = "Problème déplacé vers la gauche."
    redirect_to virtualtest_path(@t, :p => @problem.id)
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie qu'on est root si on veut supprimer un problème en ligne
  def root_problem_user
    @problem = Problem.find(params[:id])
    redirect_to problem_path(@problem) if (!current_user.sk.root && @problem.online && @problem.chapter.online)
  end

  # Vérifie qu'on peut voir ce problème
  def has_access
    @problem = Problem.find(params[:id])
    visible = true
    if !signed_in? || !current_user.sk.admin?
      @problem.chapters.each do |c|
        visible = false if !signed_in? || !current_user.sk.chap_solved?(c)
      end
    end

    t = @problem.virtualtest
    if !t.nil?
      if !signed_in?
        visible = false
      elsif !current_user.sk.admin?
        if current_user.sk.status(t) <= 0
          visible = false
        end
      end
    end

    redirect_to root_path if !visible
  end

  # Vérifie que le problème est en ligne
  def online_problem
    redirect_to root_path if !@problem.online && !current_user.sk.admin
  end

  # Vérifie que le problème peut être en ligne
  def can_be_online
    @problem = Problem.find(params[:problem_id])
    ok = true
    nombre = 0
    @problem.chapters.each do |c|
      nombre = nombre+1
      ok = false if !c.online
    end
    redirect_to @problem if !ok || nombre == 0
  end

  # Vérifie que l'on a assez de points si on est étudiant
  def enough_points
    if !current_user.sk.admin?
      score = current_user.sk.rating
      redirect_to root_path if score < 200
    end
  end
end

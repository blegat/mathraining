#encoding: utf-8
class ProblemsController < ApplicationController
  before_action :signed_in_user, only: [:show, :edit, :new, :explanation, :markscheme]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create, :order_minus, :order_plus, :put_online, :update_explanation, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_action :admin_user, only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online, :explanation, :update_explanation, :markscheme, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_action :get_problem, only: [:edit, :update, :show, :destroy]
  before_action :get_problem2, only: [:explanation, :update_explanation, :markscheme, :update_markscheme, :order_minus, :order_plus, :delete_prerequisite, :add_prerequisite, :add_virtualtest, :put_online]
  before_action :get_section, only: [:new, :create]
  before_action :offline_problem, only: [:destroy]
  before_action :has_access, only: [:show]
  before_action :online_problem, only: [:show]
  before_action :can_be_online, only: [:put_online]
  before_action :enough_points, only: [:show]

  # Voir le problème : il faut avoir accès
  def show
  end

  # Créer un problème : il faut être admin
  def new
    @problem = Problem.new
  end

  # Editer un problème : il faut être admin
  def edit
  end

  # Créer un problème 2 : il faut être admin
  def create
    @problem = Problem.new
    @problem.statement = params[:problem][:statement]
    @problem.origin = params[:problem][:origin]
    @problem.level = params[:problem][:level]
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

  # Supprimer un problème : seulement si hors-ligne, et il faut être admin
  def destroy
    @problem.destroy
    flash[:success] = "Problème supprimé."
    redirect_to pb_sections_path(@problem.section)
  end

  # Mettre un problème en ligne : il faut qu'il puisse l'être
  def put_online
    @problem.online = true
    if @problem.virtualtest_id == 0
      @problem.markscheme = ""
    end
    @problem.save
    @section = @problem.section
    @section.max_score = @section.max_score + @problem.value
    @section.save
    redirect_to problem_path(@problem)
  end

  # Modifier l'explication d'un problème
  def explanation
  end
  
  # Modifier le marking scheme d'un problème
  def markscheme
  end

  # Modifier l'explication d'un problème 2
  def update_explanation
    @problem.explanation = params[:problem][:explanation]
    if @problem.save
      flash[:success] = "Élements de solution modifiés."
      redirect_to problem_path(@problem)
    else
      render 'explanation'
    end
  end
  
  # Modifier le marking scheme d'un problème 2
  def update_markscheme
    @problem.markscheme = params[:problem][:markscheme]
    if @problem.save
      flash[:success] = "Marking scheme modifié."
      redirect_to problem_path(@problem)
    else
      render 'markscheme'
    end
  end

  # Supprimer un prérequis
  def delete_prerequisite
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if !@chapter.nil?
      @problem.chapters.delete(@chapter)
    end
    redirect_to @problem
  end

  # Ajouter un prérequis
  def add_prerequisite
    if !params[:chapter_problem][:chapter_id].empty?
      @chapter = Chapter.find_by_id(params[:chapter_problem][:chapter_id])
      if !@chapter.nil?
        @problem.chapters << @chapter
      end
    end
    redirect_to @problem
  end

  # Ajouter à un test virtuel
  def add_virtualtest
    if !params[:problem][:virtualtest_id].empty?
      if params[:problem][:virtualtest_id].to_i == 0
        @problem.virtualtest_id = 0
      else
        t = Virtualtest.find(params[:problem][:virtualtest_id].to_i)
        lastnumero = t.problems.order(:position).reverse_order.first
        if lastnumero.nil?
          @problem.position = 1
        else
          @problem.position = lastnumero.position+1
        end
        @problem.virtualtest = t
      end
      @problem.save
    end
    redirect_to @problem
  end

  # Déplacer dans un test virtuel
  def order_minus
    t = @problem.virtualtest
    problem2 = t.problems.where("position < ?", @problem.position).order('position').reverse_order.first
    swap_position(@problem, problem2)
    flash[:success] = "Problème déplacé vers le haut."
    redirect_to virtualtests_path
  end

  # Déplacer dans un test virtuel
  def order_plus
    t = @problem.virtualtest
    problem2 = t.problems.where("position > ?", @problem.position).order('position').first
    swap_position(@problem, problem2)
    flash[:success] = "Problème déplacé vers le bas."
    redirect_to virtualtests_path
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_problem
    @problem = Problem.find_by_id(params[:id])
    if @problem.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_problem2
    @problem = Problem.find_by_id(params[:problem_id])
    if @problem.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_section
    @section = Section.find_by_id(params[:section_id])
    if @section.nil?
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le problème est hors-ligne pour le supprimer
  def offline_problem
    if @problem.online
      render 'errors/access_refused' and return
    end
  end

  # Vérifie qu'on peut voir ce problème
  def has_access
    visible = true
    if !@signed_in || !current_user.sk.admin?
      @problem.chapters.each do |c|
        visible = false if !@signed_in || !current_user.sk.chap_solved?(c)
      end
    end

    t = @problem.virtualtest
    if !t.nil?
      if !@signed_in
        visible = false
      elsif !current_user.sk.admin?
        if current_user.sk.status(t) <= 0
          visible = false
        end
      end
    end

    if !visible
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le problème est en ligne
  def online_problem
    if !@problem.online && !current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le problème peut être en ligne
  def can_be_online
    ok = true
    nombre = 0
    @problem.chapters.each do |c|
      nombre = nombre+1
      ok = false if !c.online
    end
    redirect_to @problem if !ok || nombre == 0
  end
end

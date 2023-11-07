#encoding: utf-8
class ProblemsController < ApplicationController
  before_action :signed_in_user, only: [:show, :edit, :new, :explanation, :markscheme]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create, :order, :put_online, :update_explanation, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_action :admin_user, only: [:destroy, :update, :edit, :new, :create, :order, :put_online, :explanation, :update_explanation, :markscheme, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  
  before_action :get_problem, only: [:edit, :update, :show, :destroy]
  before_action :get_problem2, only: [:explanation, :update_explanation, :markscheme, :update_markscheme, :order, :delete_prerequisite, :add_prerequisite, :add_virtualtest, :put_online]
  before_action :get_section, only: [:new, :create]
  
  before_action :offline_problem, only: [:destroy, :put_online]
  before_action :user_that_can_see_problem, only: [:show]
  before_action :online_problem_or_admin, only: [:show]
  before_action :can_be_online, only: [:put_online]

  # Show one problem
  def show
    flash.now[:info] = @no_new_submission_message if @no_new_submission and params.has_key?("sub") and params[:sub] == "0"
    if params.has_key?("auto") # Automatically show the correct submission of current user, if any
      s = current_user.sk.solvedproblems.where(:problem_id => @problem).first
      if s.nil?
        redirect_to problem_path(@problem)
      else
        redirect_to problem_path(@problem, :sub => s.submission_id)
      end
    end
  end

  # Create a problem (show the form)
  def new
    @problem = Problem.new
  end

  # Update a problem (show the form)
  def edit
  end

  # Create a problem (send the form)
  def create
    @problem = Problem.new(params.require(:problem).permit(:statement, :origin, :level))
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

  # Update a problem (send the form)
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

  # Delete a problem
  def destroy
    @problem.destroy
    flash[:success] = "Problème supprimé."
    redirect_to pb_sections_path(@problem.section)
  end

  # Put a problem online
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

  # Update the explanation of a problem (show the form)
  def explanation
  end
  
  # Update the marking scheme of a problem (show the form)
  def markscheme
  end

  # Update the explanation of a problem (send the form)
  def update_explanation
    @problem.explanation = params[:problem][:explanation]
    if @problem.save
      flash[:success] = "Élements de solution modifiés."
      redirect_to problem_path(@problem)
    else
      render 'explanation'
    end
  end
  
  # Update the marking scheme of a problem (send the form)
  def update_markscheme
    @problem.markscheme = params[:problem][:markscheme]
    if @problem.save
      flash[:success] = "Marking scheme modifié."
      redirect_to problem_path(@problem)
    else
      render 'markscheme'
    end
  end

  # Delete a prerequisite to one problem
  def delete_prerequisite
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if !@chapter.nil?
      @problem.chapters.delete(@chapter)
    end
    redirect_to @problem
  end

  # Add a prerequisite to one problem
  def add_prerequisite
    if !params[:chapter_problem][:chapter_id].empty?
      @chapter = Chapter.find_by_id(params[:chapter_problem][:chapter_id])
      if !@chapter.nil?
        @problem.chapters << @chapter
      end
    end
    redirect_to @problem
  end

  # Add a problem to a virtualtest
  def add_virtualtest
    if !params[:problem][:virtualtest_id].empty?
      if params[:problem][:virtualtest_id].to_i == 0
        @problem.virtualtest_id = 0
      else
        t = Virtualtest.find(params[:problem][:virtualtest_id].to_i)
        lastnumero = t.problems.order(:position).last
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

  # Move a problem to a new position in its virtualtest
  def order
    t = @problem.virtualtest
    problem2 = t.problems.where("position = ?", params[:new_position]).first
    if !problem2.nil? and problem2 != @problem
      res = swap_position(@problem, problem2)
      flash[:success] = "Problème déplacé#{res}." 
    end
    redirect_to virtualtests_path
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the problem
  def get_problem
    @problem = Problem.find_by_id(params[:id])
    return if check_nil_object(@problem)
  end
  
  # Get the problem (v2)
  def get_problem2
    @problem = Problem.find_by_id(params[:problem_id])
    return if check_nil_object(@problem)
  end
  
  # Get the section
  def get_section
    @section = Section.find_by_id(params[:section_id])
    return if check_nil_object(@section)
  end
  
  ########## CHECK METHODS ##########

  # Check that the problem is offline
  def offline_problem
    return if check_online_object(@problem)
  end

  # Check that the problem is online or current user is admin
  def online_problem_or_admin
    if !@problem.online && !current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end

  # Check that the problem can be put online
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

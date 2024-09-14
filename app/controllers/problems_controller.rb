#encoding: utf-8
class ProblemsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new, :edit, :edit_explanation, :edit_markscheme, :manage_externalsolutions]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create, :order, :put_online, :update_explanation, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :order, :put_online, :edit_explanation, :update_explanation, :edit_markscheme, :update_markscheme, :add_prerequisite, :delete_prerequisite, :add_virtualtest, :manage_externalsolutions]
  
  before_action :get_problem, only: [:show, :edit, :update, :destroy]
  before_action :get_problem2, only: [:edit_explanation, :update_explanation, :edit_markscheme, :update_markscheme, :order, :delete_prerequisite, :add_prerequisite, :add_virtualtest, :put_online, :manage_externalsolutions]
  before_action :get_section, only: [:new, :create]
  
  before_action :offline_problem, only: [:destroy, :put_online]
  before_action :user_that_can_see_problem, only: [:show]
  before_action :can_be_online, only: [:put_online]

  # Show one problem
  def show
    flash.now[:info] = @no_new_submission_message if @no_new_submission and params.has_key?("sub") and params[:sub] == "0"
    if params.has_key?("auto") # Automatically show the correct submission of current user, if any
      s = current_user.sk.solvedproblems.where(:problem_id => @problem).first
      if s.nil?
        redirect_to problem_path(@problem) and return
      else
        redirect_to problem_path(@problem, :sub => s.submission_id) and return
      end
    end
    
    if params.has_key?("sub")
      if params[:sub].to_i == 0 # New submission
        @submission = @problem.submissions.where(:user => current_user.sk, :status => :draft).first # In case there is a draft
        @submission = Submission.new if @submission.nil? # In case there is no draft
      else
        @submission = Submission.find_by_id(params[:sub].to_i)
        @correction = Correction.new if @submission.visible?
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
    @problem.update_attribute(:online, true)
    if @problem.virtualtest_id == 0
      @problem.update_attribute(:markscheme, "")
    end
    @section = @problem.section
    @section.update_attribute(:max_score, @section.max_score + @problem.value)
    redirect_to problem_path(@problem)
  end

  # Update the explanation of a problem (show the form)
  def edit_explanation
  end
  
  # Update the marking scheme of a problem (show the form)
  def edit_markscheme
  end

  # Update the explanation of a problem (send the form)
  def update_explanation
    if @problem.update(:explanation => params[:problem][:explanation]) # Do not use update_attribute because it does not trigger validations
      flash[:success] = "Élements de solution modifiés."
      redirect_to problem_path(@problem)
    else
      render 'edit_explanation'
    end
  end
  
  # Update the marking scheme of a problem (send the form)
  def update_markscheme
    if @problem.update(:markscheme => params[:problem][:markscheme]) # Do not use update_attribute because it does not trigger validations
      flash[:success] = "Marking scheme modifié."
      redirect_to problem_path(@problem)
    else
      render 'edit_markscheme'
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
  
  # Manage the externalsolutions (and extracts of these) of the problem
  def manage_externalsolutions
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

  # Check that the problem can be put online
  def can_be_online
    redirect_to @problem if @problem.chapters.count == 0
    @problem.chapters.each do |c|
      redirect_to @problem if !c.online
    end
  end
end

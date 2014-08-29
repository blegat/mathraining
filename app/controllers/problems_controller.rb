#encoding: utf-8
class ProblemsController < ApplicationController
  before_filter :signed_in_user, only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online, :explanation, :update_explanation, :add_prerequisite, :delete_prerequisite]
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online, :explanation, :update_explanation, :add_prerequisite, :delete_prerequisite]
  before_filter :root_user, only: [:destroy]
  before_filter :has_access, only: [:show]
  before_filter :online_problem, only: [:show]
  before_filter :can_be_online, only: [:put_online]

  def show
  end

  def new
    @problem = Problem.new
    @section = Section.find(params[:section_id])
  end

  def edit
    @problem = Problem.find(params[:id])
  end

  def create
    @problem = Problem.new
    @problem.name = ""
    @problem.statement = params[:problem][:statement]
    @problem.level = params[:problem][:level]
    
    nombre = 0
    loop do
      nombre = @problem.level*100 + @problem.section.id*1000+rand(100)
      break if Problem.where(:number => nombre).count == 0
    end
    @problem.number = nombre
    
    @problem.explanation = ""
    @section = Section.find_by_id(params[:section_id])
    if @section.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    @problem.online = false
    @problem.section = @section
    if @problem.save
      flash[:success] = "Problème ajouté."
      redirect_to problem_path(@problem)
    else
      render 'new'
    end
  end

  def update
  
    Problem.all.each do |p|
      p.section = p.chapter.section
    end
  
  
    @problem = Problem.find(params[:id])
    @problem.name = ""
    @problem.statement = params[:problem][:statement]
    
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

  def put_online
    @problem.online = true
    @problem.save
    redirect_to problem_path(@problem)
  end

  def explanation
    @problem = Problem.find(params[:problem_id])
  end

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
  
  def delete_prerequisite
    @chapter = Chapter.find(params[:chapter_id])
    @problem = Problem.find(params[:problem_id])    
    @problem.chapters.delete(@chapter)
    redirect_to @problem
  end
  
  def add_prerequisite
    @problem = Problem.find(params[:problem_id])	
    if !params[:chapter_problem][:chapter_id].empty?
      @chapter = Chapter.find(params[:chapter_problem][:chapter_id])
      @problem.chapters << @chapter
    end
    redirect_to @problem
  end

  private

  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end

  def root_user
    @problem = Problem.find(params[:id])
    redirect_to problem_path(@problem) if (!current_user.sk.root && @problem.online && @problem.chapter.online)
  end
  
  def has_access
    @problem = Problem.find(params[:id])
    if !signed_in? || !current_user.sk.admin?
      visible = true
      @problem.chapters.each do |c|
        visible = false if !signed_in? || !current_user.sk.solved?(c)
      end
      redirect_to root_path if !visible
    end
  end
  
  def online_problem
    redirect_to root_path if !@problem.online && !current_user.sk.admin
  end
  
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

  def point_attribution(user)
    user.point.rating = 0
    partials = user.pointspersections
    partial = Array.new
    
    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      if partial[s.id].nil?
        newpoint = Pointspersection.new
        newpoint.points = 0
        newpoint.section_id = s.id
        user.pointspersections << newpoint
        partial[s.id] = user.pointspersections.where(:section_id => s.id).first
      end
      partial[s.id].points = 0
    end

    user.solvedexercises.each do |e|
      if e.correct
        exo = e.exercise
        pt = exo.value

        if !exo.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[exo.chapter.section.id].points = partial[exo.chapter.section.id].points + pt
      end
    end

    user.solvedqcms.each do |q|
      if q.correct
        qcm = q.qcm
        pt = qcm.value

        if !qcm.chapter.section.fondation? # Pas un fondement
          user.point.rating = user.point.rating + pt
        end

        partial[qcm.chapter.section.id].points = partial[qcm.chapter.section.id].points + pt
      end
    end

    user.solvedproblems.each do |p|
      problem = p.problem
      pt = problem.value

      if !problem.section.fondation? # Pas un fondement
        user.point.rating = user.point.rating + pt
      end

      partial[problem.section.id].points = partial[problem.section.id].points + pt
    end

    user.point.save
    Section.all.each do |s|
      partial[s.id].save
    end

  end
end

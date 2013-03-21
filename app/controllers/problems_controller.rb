#encoding: utf-8
class ProblemsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online]


  def new
    @problem = Problem.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @problem = Problem.find(params[:id])
  end

  def create
    @problem = Problem.new
    @problem.name = params[:problem][:name]
    @problem.statement = params[:problem][:statement]
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if @chapter.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    if @chapter.online
      @problem.online = false
    else
      @problem.online = true
    end
    @problem.chapter = @chapter
    if @chapter.problems.empty?
      @problem.position = 1
    else
      need = @chapter.problems.order('position').reverse_order.first
      @problem.position = need.position + 1
    end
    if @problem.save
      flash[:success] = "Problème ajouté."
      redirect_to chapter_path(@chapter, :type => 4, :which => @problem.id)
    else
      render 'new'
    end
  end

  def update
    @problem = Problem.find(params[:id])
    @problem.name = params[:problem][:name]
    @problem.statement = params[:problem][:statement]
    if @problem.save
      flash[:success] = "Problème modifié."
      redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id)
    else
      render 'edit'
    end
  end

  def destroy
    @problem = Problem.find(params[:id])
    @chapter = @problem.chapter
    @problem.destroy
    flash[:success] = "Problème supprimé."
    redirect_to @chapter
  end
  
  def put_online
    @problem = Problem.find(params[:problem_id])
    @problem.online = true
    @problem.save
    redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id)
  end

  def order_minus
    @problem = Problem.find(params[:problem_id])
    @problem2 = @problem.chapter.problems.where("position < ?", @problem.position).order('position').reverse_order.first
    err = swap_position(@problem, @problem2)
    if err.nil?
      flash[:success] = "Problème déplacé vers le haut."
    else
      flash[:error] = err
    end
    redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id)
  end

  def order_plus
    @problem = Problem.find(params[:problem_id])
    @problem2 = @problem.chapter.problems.where("position > ?", @problem.position).order('position').first
    err = swap_position(@problem, @problem2)
    if err.nil?
      flash[:success] = "Problème déplacé vers le bas."
    else
      flash[:error] = err
    end
    redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id)
  end

  private
  
  def swap_position(a, b)
    err = nil
    Problem.transaction do
      x = a.position
      a.position = b.position
      b.position = x
      a.save(validate: false)
      b.save(validate: false)
      unless a.valid? and b.valid?
        erra = get_errors(a)
        errb = get_errors(b)
        if erra.nil?
          if errb.nil?
            err = "Quelque chose a mal tourné."
          else
            err = "#{errb} pour #{b.name}"
          end
        else
          # if a is not valid b.valid? is not executed
          err = "#{erra} pour #{a.name}"
        end
        raise ActiveRecord::Rollback
      end
    end
    return err
  end

  def admin_user
    redirect_to root_path unless current_user.admin?
  end
end

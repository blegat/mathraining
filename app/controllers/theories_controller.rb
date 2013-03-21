#encoding: utf-8
class TheoriesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online]


  def new
    @theory = Theory.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @theory = Theory.find(params[:id])
  end

  def create
    @theory = Theory.new
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @theory.online = false
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if @chapter.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    @theory.chapter = @chapter
    if @chapter.theories.empty?
      @theory.position = 1
    else
      need = @chapter.theories.order('position').reverse_order.first
      @theory.position = need.position + 1
    end
    if @theory.save
      flash[:success] = "Point théorique ajouté."
      redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
    else
      render 'new'
    end
  end

  def update
    @theory = Theory.find(params[:id])
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    if @theory.save
      flash[:success] = "Point théorique modifié."
      redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
    else
      render 'edit'
    end
  end

  def destroy
    @theory = Theory.find(params[:id])
    @chapter = @theory.chapter
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end
  
  def put_online
    @theory = Theory.find(params[:theory_id])
    @theory.online = true
    @theory.save
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  def order_minus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position < ?", @theory.position).order('position').reverse_order.first
    err = swap_position(@theory, @theory2)
    if err.nil?
      flash[:success] = "Point théorique déplacé vers le haut."
    else
      flash[:error] = err
    end
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  def order_plus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position > ?", @theory.position).order('position').first
    err = swap_position(@theory, @theory2)
    if err.nil?
      flash[:success] = "Point théorique déplacé vers le bas."
    else
      flash[:error] = err
    end
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end
  
  def read
    @theory = Theory.find(params[:theory_id])
    current_user.theories << @theory
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end
  
  def unread
    @theory = Theory.find(params[:theory_id])
    current_user.theories.delete(@theory)
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  private
  
  def swap_position(a, b)
    err = nil
    Theory.transaction do
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
            err = "#{errb} pour #{b.title}"
          end
        else
          # if a is not valid b.valid? is not executed
          err = "#{erra} pour #{a.title}"
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

#encoding: utf-8
class QcmsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus]
 
  def new
    @qcm = Qcm.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @qcm = Qcm.find(params[:id])
  end

  def create
    @qcm = Qcm.new
    @qcm.chapter_id = params[:chapter_id]
    @qcm.statement = params[:qcm][:statement]
    if params[:qcm][:many_answers] == '1'
      @qcm.many_answers = true
    else
      @qcm.many_answers = false
    end
    before = 0
    before2 = 0
    if Exercise.exists?(["chapter_id = ?", params[:chapter_id]])
      need = Exercise.where("chapter_id = ?", params[:chapter_id]).order('position').reverse_order.first
      before = need.position
    end
    if Qcm.exists?(["chapter_id = ?", params[:chapter_id]])
      need = Qcm.where("chapter_id = ?", params[:chapter_id]).order('position').reverse_order.first
      before2 = need.position
    end
    @qcm.position = maximum(before, before2)+1
    @chapter = Chapter.find(params[:chapter_id])
    if @qcm.save
      flash[:success] = "QCM ajouté."
      redirect_to chapter_path(@chapter, :type => 3, :which => @qcm.id)
    else
      render 'new'
    end
    
  end

  def update
    @qcm = Qcm.find(params[:id])
    @qcm.statement = params[:qcm][:statement]
    if params[:qcm][:many_answers] == '1'
      @qcm.many_answers = true
    else
      @qcm.many_answers = false
    end
    if @qcm.save
      flash[:success] = "QCM modifié."
      redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
    else
      render 'edit'
    end
      
  end
  
  def destroy
    @qcm = Qcm.find(params[:id])
    @chapter = @qcm.chapter
    @qcm.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end
  
  def order_minus
    @qcm = Qcm.find(params[:qcm_id])
    x = 0
    if Exercise.exists?(["position < ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id])
      @exercise2 = Exercise.where("position < ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id).order('position').reverse_order.first
      x = @exercise2.position
    end
    y = 0
    if Qcm.exists?(["position < ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id])
      @qcm2 = Qcm.where("position < ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id).order('position').reverse_order.first
      y = @qcm2.position
    end
    if x > y
      @exercise2.position = @qcm.position
      @qcm.position = x
      @qcm.save
      @exercise2.save
    else
      @qcm2.position = @qcm.position
      @qcm.position = y
      @qcm.save
      @qcm2.save
    end
    flash[:success] = "QCM déplacé vers le haut."
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
  end
  
  def order_plus
    @qcm = Qcm.find(params[:qcm_id])
    x = 12345678
    if Exercise.exists?(["position > ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id])
      @exercise2 = Exercise.where("position > ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id).order('position').first
      x = @exercise2.position
    end
    y = 12345678
    if Qcm.exists?(["position > ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id])
      @qcm2 = Qcm.where("position > ? AND chapter_id = ?", @qcm.position, @qcm.chapter.id).order('position').first
      y = @qcm2.position
    end
    if x < y
      @exercise2.position = @qcm.position
      @qcm.position = x
      @qcm.save
      @exercise2.save
    else
      @qcm2.position = @qcm.position
      @qcm.position = y
      @qcm.save
      @qcm2.save
    end
    flash[:success] = "QCM déplacé vers le bas."
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
  end
  

  private
  
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  
  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end
end

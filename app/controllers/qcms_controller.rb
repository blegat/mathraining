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
    @chapter = Chapter.find(params[:chapter_id])
    if @chapter.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    @qcm.chapter = @chapter
    @qcm.statement = params[:qcm][:statement]
    if params[:qcm][:many_answers] == '1'
      @qcm.many_answers = true
    else
      @qcm.many_answers = false
    end
    before = 0
    before2 = 0
    unless @chapter.exercises.empty?
      need = @chapter.exercises.order('position').reverse_order.first
      before = need.position
    end
    if @chapter.qcms.empty?
      need = @chapter.qcms.order('position').reverse_order.first
      before2 = need.position
    end
    @qcm.position = maximum(before, before2) + 1
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

  def order_op(sign, fun, name)
    @qcm = Qcm.find(params[:qcm_id])
    x = nil
    if @qcm.chapter.exercises.exists?(["position #{sign} ?", @qcm.position])
      if sign == '<'
        exercise2 = @qcm.chapter.exercises.where("position #{sign} ?", @qcm.position, @qcm.chapter.id).order('position').reverse_order.first
      else
        exercise2 = @qcm.chapter.exercises.where("position #{sign} ?", @qcm.position, @qcm.chapter.id).order('position').first
      end
      x = exercise2.position
    end
    y = nil
    if @qcm.chapter.qcms.exists?(["position #{sign} ?", @qcm.position])
      if sign == '<'
        qcm2 = @qcm.chapter.qcms.where("position #{sign} ?", @qcm.position).order('position').reverse_order.first
      else
        qcm2 = @qcm.chapter.qcms.where("position #{sign} ?", @qcm.position).order('position').first
      end
      y = qcm2.position
    end
    if x.nil? and y.nil?
      flash[:notice] = "QCM déjà le plus #{name} possible."
    else
      if not x.nil? and (y.nil? or fun.call x, y)
        other = exercise2
      else
        other = qcm2
      end
      err = swap_position(@qcm, other)
      if err.nil?
        flash[:success] = "QCM déplacé vers le #{name}."
      else
        flash[:error] = err
      end
    end
    redirect_to chapter_path(@qcm.chapter, :type => 3, :which => @qcm.id)
  end

  def order_minus
    order_op('<', lambda { |x, y| x < y }, 'haut')
  end

  def order_plus
    order_op('>', lambda { |x, y| x > y }, 'bas')
  end


  private

  def swap_position(a, b)
    err = nil
    Qcm.transaction do
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

  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end
end

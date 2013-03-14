#encoding: utf-8
class QcmsController < QuestionsController
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

  def order_minus
    qcm = Qcm.find(params[:qcm_id])
    order_op(true, false, qcm)
  end

  def order_plus
    qcm = Qcm.find(params[:qcm_id])
    order_op(false, false, qcm)
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

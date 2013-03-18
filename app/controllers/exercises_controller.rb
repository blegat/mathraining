#encoding: utf-8
class ExercisesController < QuestionsController
  before_filter :signed_in_user
  before_filter :online_chapter,
    only: [:new, :create]
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus]

  def new
    @exercise = Exercise.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @exercise = Exercise.find(params[:id])
    if !@exercise.decimal
      @exercise.answer = @exercise.answer.to_i
    end
  end

  def create
    @exercise = Exercise.new
    @exercise.chapter_id = params[:chapter_id]
    @exercise.statement = params[:exercise][:statement]
    if params[:exercise][:decimal] == '1'
      @exercise.decimal = true
      @exercise.answer = params[:exercise][:answer].to_f
    else
      @exercise.decimal = false
      @exercise.answer = params[:exercise][:answer].to_i
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
    @exercise.position = maximum(before, before2)+1
    @chapter = Chapter.find(params[:chapter_id])
    if @exercise.save
      flash[:success] = "Exercice ajouté."
      redirect_to chapter_path(@chapter, :type => 2, :which => @exercise.id)
    else
      render 'new'
    end
  end

  def update
    @exercise = Exercise.find(params[:id])
    @exercise.statement = params[:exercise][:statement]
    if params[:exercise][:decimal] == '1'
      @exercise.decimal = true
      @exercise.answer = params[:exercise][:answer].to_f
    else
      @exercise.decimal = false
      @exercise.answer = params[:exercise][:answer].to_i
    end
    if @exercise.save
      flash[:success] = "Exercice modifié."
      redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
    else
      render 'edit'
    end
  end

  def destroy
    @exercise = Exercise.find(params[:id])
    @chapter = @exercise.chapter
    @exercise.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end
  
  def order_minus
    ex = Exercise.find(params[:exercise_id])
    order_op(true, true, ex)
  end
  
  def order_plus
    ex = Exercise.find(params[:exercise_id])
    order_op(false, true, ex)
  end
  
  private
  
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  
  def online_chapter
    @chapter = Chapter.find(params[:chapter_id])
    if @chapter.online
      redirect_to chapter_path(@chapter)
    end
  end
  
  def maximum(a, b)
    if a > b
      return a
    else
      return b
    end
  end
end

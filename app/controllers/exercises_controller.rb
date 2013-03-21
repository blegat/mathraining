#encoding: utf-8
class ExercisesController < QuestionsController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus, :put_online]

  def new
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
  end

  def edit
    @exercise = Exercise.find(params[:id])
    if !@exercise.decimal
      @exercise.answer = @exercise.answer.to_i
    end
  end

  def create
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
    if @chapter.online
      @exercise.online = false
    else
      @exercise.online = true
    end
    @exercise.chapter_id = params[:chapter_id]
    @exercise.statement = params[:exercise][:statement]
    if params[:exercise][:decimal] == '1'
      @exercise.decimal = true
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_f
    else
      @exercise.decimal = false
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_i
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
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_f unless @exercise.chapter.online && @exercise.online
    else
      @exercise.decimal = false
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_i unless @exercise.chapter.online && @exercise.online
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
    @exercise = Exercise.find(params[:exercise_id])
    order_op(true, true, @exercise)
  end
  
  def order_plus
    @exercise = Exercise.find(params[:exercise_id])
    order_op(false, true, @exercise)
  end
  
  def put_online
    @exercise = Exercise.find(params[:exercise_id])
    @exercise.online = true
    @exercise.save
    redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
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

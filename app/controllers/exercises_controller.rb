#encoding: utf-8
class ExercisesController < QuestionsController
  before_action :signed_in_user, only: [:new, :edit, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order_minus, :order_plus, :put_online, :update_explanation]
  before_action :admin_user
  before_action :offline_exercise, only: [:destroy]

  # Créer un nouvel exercice : il faut être admin
  def new
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
  end

  # Editer un exercice : il faut être admin
  def edit
    @exercise = Exercise.find(params[:id])
    if !@exercise.decimal
      @exercise.answer = @exercise.answer.to_i
    end
  end

  # Créer un nouvel exercice 2 : il faut être admin
  def create
    @chapter = Chapter.find(params[:chapter_id])
    @exercise = Exercise.new
    @exercise.online = false

    @exercise.chapter_id = params[:chapter_id]
    @exercise.statement = params[:exercise][:statement]
    @exercise.level = params[:exercise][:level]
    if @chapter.section.fondation?
      @exercise.level = 0
    end
    @exercise.explanation = ""
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
    @exercise.position = [before, before2].max + 1
    @chapter = Chapter.find(params[:chapter_id])
    if @exercise.save
      flash[:success] = "Exercice ajouté."
      redirect_to chapter_path(@chapter, :type => 2, :which => @exercise.id)
    else
      render 'new'
    end
  end

  # Editer un exercice 2 : il faut être admin
  def update
    @exercise = Exercise.find(params[:id])
    @exercise.statement = params[:exercise][:statement]

    unless @exercise.online
      if params[:exercise][:decimal] == '1'
        @exercise.decimal = true
      else
        @exercise.decimal = false
      end

      @exercise.level = params[:exercise][:level]
      if @exercise.chapter.section.fondation?
        @exercise.level = 0
      end
    end

    if @exercise.decimal
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_f unless @exercise.online
    else
      @exercise.answer = params[:exercise][:answer].gsub(",",".").to_i unless @exercise.online
    end

    if @exercise.save
      flash[:success] = "Exercice modifié."
      redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
    else
      render 'edit'
    end
  end

  # Supprimer un exercice : il faut être admin
  def destroy
    @chapter = @exercise.chapter
    @exercise.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Ordre moins : il faut être admin
  def order_minus
    @exercise = Exercise.find(params[:exercise_id])
    order_op(true, true, @exercise)
  end

  # Ordre plus : il faut être admin
  def order_plus
    @exercise = Exercise.find(params[:exercise_id])
    order_op(false, true, @exercise)
  end

  # Mettre en ligne : il faut être admin
  def put_online
    @exercise = Exercise.find(params[:exercise_id])
    @exercise.online = true
    @exercise.save
    @section = @exercise.chapter.section
    @section.max_score = @section.max_score + @exercise.value
    @section.save
    redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
  end

  # Modifier l'explication : il faut être admin
  def explanation
    @exercise = Exercise.find(params[:exercise_id])
  end

  # Modifier l'explication 2 : il faut être admin
  def update_explanation
    @exercise = Exercise.find(params[:exercise_id])
    @exercise.explanation = params[:exercise][:explanation]
    if @exercise.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id)
    else
      render 'explanation'
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie que l'exercice est hors-ligne
  def offline_exercise
    @exercise = Exercise.find(params[:id])
    redirect_to chapter_path(@exercise.chapter, :type => 2, :which => @exercise.id) if @exercise.online
  end
end

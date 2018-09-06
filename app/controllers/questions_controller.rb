#encoding: utf-8
class QuestionsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :manage_items, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :remove_item, :add_item, :switch_item, :update_item, :order_minus, :order_plus, :put_online, :update_explanation]
  before_action :admin_user
  before_action :online_question, only: [:add_item, :remove_item]
  before_action :offline_question, only: [:destroy]

  # Créer une question
  def new
    @chapter = Chapter.find(params[:chapter_id])
    @question = Question.new
  end

  # Editer une question
  def edit
    @question = Question.find(params[:id])
    if !@question.decimal
      @question.answer = @question.answer.to_i
    end
  end

  # Créer une question 2
  def create
    @chapter = Chapter.find(params[:chapter_id])
    @question = Question.new
    @question.online = false
    @question.chapter = @chapter
    @question.statement = params[:question][:statement]
    @question.level = params[:question][:level]
    if @chapter.section.fondation?
      @question.level = 0
    end
    @question.explanation = ""
    if params[:question][:is_qcm] == '1'
      @question.is_qcm = true
      if params[:question][:many_answers] == '1'
        @question.many_answers = true
      else
        @question.many_answers = false
      end
      @question.answer = 0
    else
      @question.is_qcm = false
      if params[:question][:decimal] == '1'
        @question.decimal = true
        @question.answer = params[:question][:answer].gsub(",",".").to_f
      else
        @question.decimal = false
        @question.answer = params[:question][:answer].gsub(",",".").to_i
      end
    end
    before = 0
    unless @chapter.questions.empty?
      need = @chapter.questions.order('position').reverse_order.first
      before = need.position
    end
    @question.position = before + 1
    if @question.save
      flash[:success] = "Exercice ajouté."
      if @question.is_qcm
        redirect_to question_manage_items_path(@question)
      else
        redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
      end
    else
      render 'new'
    end
  end

  # Editer un exercice 2
  def update
    @question = Question.find(params[:id])
    @question.statement = params[:question][:statement]
    unless @question.online
      @question.level = params[:question][:level]
      if @question.chapter.section.fondation?
        @question.level = 0
      end
      if @question.is_qcm
        if params[:question][:many_answers] == '1'
          @question.many_answers = true
        else
          if @question.many_answers
            # Must check there is only one true
            i = 0
            @question.items.each do |c|
              if c.ok
                if i > 0
                  c.ok = false
                  flash[:info] = "Attention, il y avait plusieurs réponses correctes à cet exercice, seule la première a été gardée."
                  c.save
                end
                i = i+1
              end
            end
            if @question.items.count > 0 && i == 0
              # There is no good answer
              flash[:info] = "Attention, il n'y avait aucune réponse correcte à cet exercice, une réponse correcte a été rajoutée aléatoirement."
              @item = @question.items.first
              @item.ok = true
              @item.save
            end
          end
          @question.many_answers = false
        end
      else
        if params[:question][:decimal] == '1'
          @question.decimal = true
          @question.answer = params[:question][:answer].gsub(",",".").to_f
        else
          @question.decimal = false
          @question.answer = params[:question][:answer].gsub(",",".").to_i
        end
      end
    end
    
    if @question.save
      redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
    else
      render 'edit'
    end
  end

  # Supprimer un exercice (plus possible si en ligne)
  def destroy
    @chapter = @question.chapter
    @question.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Page pour modifier les choix
  def manage_items
    @question = Question.find(params[:question_id])
  end

  # Supprimer un choix
  def remove_item
    @item = Item.find(params[:id])
    if !@question.many_answers && @item.ok && @question.items.count > 1
      # No more good answer
      # We put one in random to true
      @item.destroy
      @item2 = @question.items.last
      @item2.ok = true
      @item2.save
      flash[:info] = "Vous avez supprimé une réponse correcte : une autre a été mise correcte à la place par défaut."
    else
      @item.destroy
    end
    redirect_to question_manage_items_path(params[:question_id])
  end

  # Ajouter un choix
  def add_item
    @item = Item.new
    @item.question_id = params[:question_id]
    @item.ok = params[:item][:ok]
    @item.ans = params[:item][:ans]
    if !@question.many_answers && @item.ok && @question.items.count > 0
      flash[:info] = "La réponse correcte a maintenant changé (une seule réponse est possible pour cet exercice)."
      # Two good answer
      # We put the other one to false
      @question.items.each do |f|
        if f.ok
          f.ok = false
          f.save
        end
      end
    end
    if !@question.many_answers && !@item.ok && @question.items.count == 0
      flash[:info] = "Cette réponse est mise correcte par défaut. Celle-ci redeviendra erronée lorsque vous rajouterez la réponse correcte."
      @item.ok = true
    end
    unless @item.save
      flash[:info] = "Un choix ne peut être vide."
    end
    redirect_to question_manage_items_path(params[:question_id])
  end

  # Modifier la véracité d'un choix
  def switch_item
    @item = Item.find(params[:id])
    @question = @item.question
    if !@question.many_answers
      @question.items.each do |f|
        if f.ok
          f.ok = false
          f.save
        end
      end
      @item.ok = true
    else
      @item.ok = !@item.ok
    end
    @item.save
    redirect_to question_manage_items_path(params[:question_id])
  end

  # Modifier un choix
  def update_item
    @item = Item.find(params[:id])
    @item.ans = params[:item][:ans]
    if @item.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:danger] = "Un choix ne peut être vide."
    end
    redirect_to question_manage_items_path(params[:question_id])
  end

  # Déplacer
  def order_minus
    @question = Question.find(params[:question_id])
    order_op(true, @question)
  end

  # Déplacer
  def order_plus
    @question = Question.find(params[:question_id])
    order_op(false, @question)
  end

  # Mettre en ligne
  def put_online
    @question = Question.find(params[:question_id])
    @question.online = true
    @question.save
    @section = @question.chapter.section
    @section.max_score = @section.max_score + @question.value
    @section.save
    redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
  end

  # Modifier l'explication
  def explanation
    @question = Question.find(params[:question_id])
  end

  # Modifier l'explication 2
  def update_explanation
    @question = Question.find(params[:question_id])
    @question.explanation = params[:question][:explanation]
    if @question.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id)
    else
      render 'explanation'
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  # Il faut être root pour supprimer un exercice en ligne
  def offline_question
    @question = Question.find(params[:id])
    redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id) if @question.online
  end

  # Vérifie que l'exercice est en ligne
  def online_question
    @question = Question.find(params[:question_id])
    redirect_to chapter_path(@question.chapter, :type => 5, :which => @question.id) if @question.online
  end
  
  def order_op(haut, question)
    if haut
      sign = '<'
      fun = lambda { |x, y| x > y }
      name = 'haut'
    else
      sign = '>'
      fun = lambda { |x, y| x < y }
      name = 'bas'
    end
    if question.chapter.questions.exists?(["position #{sign} ?", question.position])
      if haut
        question2 = question.chapter.questions.where("position #{sign} ?", question.position).order('position').reverse_order.first
      else
        question2 = question.chapter.questions.where("position #{sign} ?", question.position).order('position').first
      end
      swap_position(question, question2)
      flash[:success] = "Exercice déplacé vers le #{name}."
    else
      flash[:info] = "Exercice déjà le plus #{name} possible."
    end
    redirect_to chapter_path(question.chapter, :type => 5, :which => question.id)
  end

  def swap_position(a, b)
    x = a.position
    a.position = b.position
    b.position = x
    a.save
    b.save
  end
end

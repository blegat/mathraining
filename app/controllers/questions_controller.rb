#encoding: utf-8
class QuestionsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :manage_items, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :remove_item, :add_item, :switch_item, :update_item, :order_minus, :order_plus, :put_online, :update_explanation, :up_item, :down_item]
  before_action :get_chapter, only: [:new, :create]
  before_action :get_question, only: [:edit, :update, :destroy]
  before_action :get_question2, only: [:manage_items, :remove_item, :add_item, :switch_item, :up_item, :down_item, :update_item, :order_minus, :order_plus, :put_online, :explanation, :update_explanation]
  before_action :creating_user
  before_action :get_item, only: [:remove_item, :switch_item, :up_item, :down_item, :update_item]
  before_action :offline_question, only: [:add_item, :remove_item, :destroy]

  # Créer une question
  def new
    @question = Question.new
  end

  # Editer une question
  def edit
    if !@question.decimal
      @question.answer = @question.answer.to_i
    end
  end

  # Créer une question 2
  def create
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
    @question.statement = params[:question][:statement]
    unless @question.online
      @question.level = params[:question][:level]
      if @chapter.section.fondation?
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
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    else
      render 'edit'
    end
  end

  # Supprimer un exercice (plus possible si en ligne)
  def destroy
    @question.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Page pour modifier les choix
  def manage_items
  end

  # Supprimer un choix
  def remove_item
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
    last_pos = 0
    last_item = @question.items.order(:position).last
    if !last_item.nil?
      last_pos = last_item.position
    end
    @item.position = last_pos+1
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
    redirect_to question_manage_items_path(@question)
  end

  # Modifier la véracité d'un choix
  def switch_item
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
    redirect_to question_manage_items_path(@question)
  end
  
  # Déplacer un choix vers le haut
  def up_item 
    order_op2(true, @item)
  end
  
  # Déplacer un choix vers le bas
  def down_item
    order_op2(false, @item)
  end

  # Modifier un choix
  def update_item
    @item.ans = params[:item][:ans]
    if @item.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:danger] = "Un choix ne peut être vide."
    end
    redirect_to question_manage_items_path(@question)
  end

  # Déplacer
  def order_minus
    order_op(true, @question)
  end

  # Déplacer
  def order_plus
    order_op(false, @question)
  end

  # Mettre en ligne
  def put_online
    @question.online = true
    @question.save
    @section = @question.chapter.section
    @section.max_score = @section.max_score + @question.value
    @section.save
    redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
  end

  # Modifier l'explication
  def explanation
  end

  # Modifier l'explication 2
  def update_explanation
    @question.explanation = params[:question][:explanation]
    if @question.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    else
      render 'explanation'
    end
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
  end
  
  def get_question
    @question = Question.find_by_id(params[:id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  def get_question2
    @question = Question.find_by_id(params[:question_id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  def get_item
    @item = Item.find_by_id(params[:id])
    return if check_nil_object(@item)
  end

  # Vérifie que l'exercice n'est pas en ligne
  def offline_question
    return if check_online_object(@question)
  end
  
  # Modification de l'ordre des exercices
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
  
  # Modification de l'ordre des choix d'un QCM
  def order_op2(haut, item)
    if haut
      sign = '<'
      fun = lambda { |x, y| x > y }
      name = 'haut'
    else
      sign = '>'
      fun = lambda { |x, y| x < y }
      name = 'bas'
    end
    if item.question.items.exists?(["position #{sign} ?", item.position])
      if haut
        item2 = item.question.items.where("position #{sign} ?", item.position).order('position').reverse_order.first
      else
        item2 = item.question.items.where("position #{sign} ?", item.position).order('position').first
      end
      swap_position(item, item2)
      flash[:success] = "Choix déplacé vers le #{name}."
    else
      flash[:info] = "Choix déjà le plus #{name} possible."
    end
    redirect_to question_manage_items_path(params[:question_id])
  end
  
  def creating_user
    unless (@signed_in && (current_user.sk.admin? || (!@chapter.online? && current_user.sk.creating_chapters.exists?(@chapter))))
      render 'errors/access_refused' and return
    end
  end
end

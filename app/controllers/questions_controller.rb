#encoding: utf-8
class QuestionsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :manage_items, :explanation]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :remove_item, :add_item, :switch_item, :update_item, :order, :put_online, :update_explanation, :order_item]
  
  before_action :get_question, only: [:edit, :update, :destroy]
  before_action :get_question2, only: [:manage_items, :remove_item, :add_item, :switch_item, :order_item, :update_item, :order, :put_online, :explanation, :update_explanation]
  before_action :get_chapter, only: [:new, :create]
  before_action :get_item, only: [:remove_item, :switch_item, :order_item, :update_item]
  
  before_action :user_that_can_update_chapter
  before_action :offline_question, only: [:add_item, :remove_item, :destroy]

  # Create a question (show the form)
  def new
    @question = Question.new
    if params[:qcm] == '1'
      @question.is_qcm = true
    end
  end

  # Update a question (show the form)
  def edit
    if !@question.decimal
      @question.answer = @question.answer.to_i
    end
  end

  # Create a question (send the form)
  def create
    @question = Question.new(:online      => false,
                             :chapter     => @chapter,
                             :statement   => params[:question][:statement],
                             :level       => (@chapter.section.fondation? ? 0 : params[:question][:level]),
                             :explanation => "À écrire")
    if params[:question][:is_qcm] == '1'
      @question.is_qcm = true
      @question.many_answers = (params[:question][:many_answers] == '1')
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
      need = @chapter.questions.order('position').last
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

  # Update a question (send the form)
  def update
    @question.statement = params[:question][:statement]
    unless @question.online
      @question.level = (@chapter.section.fondation? ? 0 : params[:question][:level])
      if @question.is_qcm
        if params[:question][:many_answers] == '1'
          @question.many_answers = true
        else
          if @question.many_answers
            # Must check there is only one true
            i = 0
            @question.items.order(:id).each do |c|
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
              @item = @question.items.order(:id).first
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

  # Delete a question
  def destroy
    @question.destroy
    flash[:success] = "Exercice supprimé."
    redirect_to @chapter
  end

  # Show page to manage items of a qcm
  def manage_items
  end

  # Delete an item of a qcm
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

  # Add an item to a qcm
  def add_item
    @item = Item.new(:question_id => params[:question_id],
                     :ok          => params[:item][:ok],
                     :ans         => params[:item][:ans])
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
      flash.clear # Remove other flash info
      flash[:danger] = error_list_for(@item)
    end
    redirect_to question_manage_items_path(@question)
  end

  # Toggle the truth of an item
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
  
  # Move an item to a new position
  def order_item
    item2 = @question.items.where("position = ?", params[:new_position]).first
    if !item2.nil? and item2 != @item
      res = swap_position(@item, item2)
      flash[:success] = "Choix déplacé#{res}." 
    end
    redirect_to question_manage_items_path(@question)
  end

  # Update an item
  def update_item
    @item.ans = params[:item][:ans]
    if @item.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:danger] = error_list_for(@item)
    end
    redirect_to question_manage_items_path(@question)
  end

  # Move a question to a new position
  def order
    question2 = @chapter.questions.where("position = ?", params[:new_position]).first
    if !question2.nil? and question2 != @question
      res = swap_position(@question, question2)
      flash[:success] = "Exercice déplacé#{res}." 
    end
    redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
  end

  # Put a question online
  def put_online
    @question.online = true
    @question.save
    @section = @question.chapter.section
    @section.max_score = @section.max_score + @question.value
    @section.save
    redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
  end

  # Update the explanation of a question (show the form)
  def explanation
  end

  # Update the explanation of a question (send the form)
  def update_explanation
    @question.explanation = params[:question][:explanation]
    if @question.save
      flash[:success] = "Explication modifiée."
      redirect_to chapter_path(@chapter, :type => 5, :which => @question.id)
    else
      render 'explanation'
    end
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the question
  def get_question
    @question = Question.find_by_id(params[:id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  # Get the question (v2)
  def get_question2
    @question = Question.find_by_id(params[:question_id])
    return if check_nil_object(@question)
    @chapter = @question.chapter
  end
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
  end
  
  # Get the item
  def get_item
    @item = Item.find_by_id(params[:id])
    return if check_nil_object(@item)
  end
  
  ########## CHECK METHODS ##########

  # Check that the question is offline
  def offline_question
    return if check_online_object(@question)
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to move one item up or down
  def order_op2(haut, item)
    if haut
      sign = '<'
      name = 'haut'
    else
      sign = '>'
      name = 'bas'
    end
    if item.question.items.exists?(["position #{sign} ?", item.position])
      if haut
        item2 = item.question.items.where("position #{sign} ?", item.position).order('position').last
      else
        item2 = item.question.items.where("position #{sign} ?", item.position).order('position').first
      end
      swap_position(item, item2)
      flash[:success] = "Choix déplacé vers le #{name}."
    end
    redirect_to question_manage_items_path(params[:question_id])
  end
  
end

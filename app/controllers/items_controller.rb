#encoding: utf-8
class ItemsController < ApplicationController
  include ChapterConcern
  
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :correct, :uncorrect, :order]
  
  before_action :get_item, only: [:update, :destroy, :correct, :uncorrect, :order]
  before_action :get_question, only: [:create]
  
  before_action :user_can_update_chapter, only: [:create, :update, :destroy, :correct, :uncorrect, :order]
  before_action :offline_question, only: [:create, :destroy, :correct, :uncorrect]

  # Add an item to a qcm
  def create
    @item = Item.new(:question => @question,
                     :ok       => params[:item][:ok],
                     :ans      => params[:item][:ans])
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
          f.update_attribute(:ok, false)
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
    redirect_to manage_items_question_path(@question)
  end
  
  # Update an item
  def update
    @item.ans = params[:item][:ans]
    if @item.save
      flash[:success] = "Réponse modifiée."
    else
      flash[:danger] = error_list_for(@item)
    end
    redirect_to manage_items_question_path(@question)
  end
  
  # Delete an item of a qcm
  def destroy
    if !@question.many_answers && @item.ok && @question.items.count > 1
      # No more good answer
      # We put one in random to true
      @item.destroy
      item2 = @question.items.last
      item2.update_attribute(:ok, true)
      flash[:info] = "Vous avez supprimé une réponse correcte : une autre a été mise correcte à la place par défaut."
    else
      @item.destroy
    end
    redirect_to manage_items_question_path(@question)
  end

  # Mark item as correct
  def correct
    if !@question.many_answers
      # Mark all items as wrong
      @question.items.each do |f|
        if f.ok
          f.update_attribute(:ok, false)
        end
      end
    end
    @item.update_attribute(:ok, true)
    redirect_to manage_items_question_path(@question)
  end
  
  # Mark item as not correct
  def uncorrect
    @item.update_attribute(:ok, false)
    redirect_to manage_items_question_path(@question)
  end
  
  # Move an item to a new position
  def order
    item2 = @question.items.where("position = ?", params[:new_position]).first
    if !item2.nil? && item2 != @item
      res = swap_position(@item, item2)
      flash[:success] = "Choix déplacé#{res}." 
    end
    redirect_to manage_items_question_path(@question)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the item
  def get_item
    @item = Item.find_by_id(params[:id])
    return if check_nil_object(@item)
    @question = @item.question
    @chapter = @question.chapter # Needed for user_can_update_chapter
  end
  
  # Get the question (if possible)
  def get_question
    @question = Question.find_by_id(params[:question_id])
    return if check_nil_object(@question)
    @chapter = @question.chapter # Needed for user_can_update_chapter
  end
  
  ########## CHECK METHODS ##########

  # Check that the question is offline
  def offline_question
    return if check_online_object(@question)
  end
  
end

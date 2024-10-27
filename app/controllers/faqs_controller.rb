#encoding: utf-8
class FaqsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :new]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create, :order]
  before_action :admin_user, only: [:destroy, :update, :edit, :new, :create, :order]
  
  before_action :get_faq, only: [:edit, :update, :destroy, :order]
  
  # Show all frequently asked questions
  def index
    @faqs = Faq.order(:position).to_a
  end

  # Create a frequently asked question (show the form)
  def new
    @faq = Faq.new
  end

  # Update a frequently asked question (show the form)
  def edit
  end
  
  # Create a frequently asked question (send the form)
  def create
    position = 1
    if Faq.count > 0
      position = Faq.order(:position).last.position + 1
    end
    @faq = Faq.create(params.require(:faq).permit(:question, :answer))
    @faq.position = position
    if @faq.save
      flash[:success] = "Question ajoutée."
      redirect_to faqs_path
    else
      render 'new'
    end
  end

  # Update a frequently asked question (send the form)
  def update
    if @faq.update(params.require(:faq).permit(:question, :answer))
      flash[:success] = "Question modifiée."
      redirect_to faqs_path
    else
      render 'edit'
    end
  end

  # Delete a frequently asked question
  def destroy
    @faq.destroy
    flash[:success] = "Question supprimée."
    redirect_to faqs_path
  end

  # Move the question to another position
  def order
    faq2 = Faq.where("position = ?", params[:new_position]).first
    if !faq2.nil? && faq2 != @faq
      res = swap_position(@faq, faq2)
      flash[:success] = "Question déplacée#{res}."
    end
    redirect_to faqs_path
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the frequently asked question
  def get_faq
    @faq = Faq.find_by_id(params[:id])
    return if check_nil_object(@faq)
  end
end

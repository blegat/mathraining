#encoding: utf-8
class FaqsController < ApplicationController
  before_action :signed_in_user, only: [:edit, :new]
  before_action :signed_in_user_danger, only: [:destroy, :update, :create, :order_minus, :order_plus]
  before_action :admin_user, only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus]
  
  before_action :get_faq, only: [:edit, :update, :destroy]
  before_action :get_faq2, only: [:order_minus, :order_plus]
  
  # Show all frequently asked questions
  def index
    @faqs = Faq.order(:position)
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
    @faq = Faq.create(params.require(:faq).permit(:question, :answer))
    if @faq.save
      @faq.position = 1
      if Faq.count > 0
        @faq.position = Faq.order(:position).last.position + 1
      end
      @faq.save
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
  
  # Move the question up
  def order_minus
    faq2 = Faq.where("position < ?", @faq.position).order('position').reverse_order.first
    swap_position(@faq, faq2)
    flash[:success] = "Question déplacée vers le haut."
    redirect_to faqs_path
  end

  # Move the question down
  def order_plus
    faq2 = Faq.where("position > ?", @faq.position).order('position').first
    swap_position(@faq, faq2)
    flash[:success] = "Question déplacée vers le bas."
    redirect_to faqs_path
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the frequently asked question
  def get_faq
    @faq = Faq.find_by_id(params[:id])
    return if check_nil_object(@faq)
  end
  
  # Get the frequently asked question
  def get_faq2
    @faq = Faq.find_by_id(params[:faq_id])
    return if check_nil_object(@faq)
  end
end

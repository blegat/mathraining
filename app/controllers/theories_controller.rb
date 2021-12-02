#encoding: utf-8
class TheoriesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order_minus, :order_plus, :put_online, :read, :unread]
  before_action :admin_user, only: [:put_online]
  
  before_action :get_theory, only: [:edit, :update, :destroy]
  before_action :get_theory2, only: [:order_minus, :order_plus, :read, :unread, :put_online]
  before_action :get_chapter, only: [:new, :create]
  
  before_action :user_that_can_update_chapter, only: [:new, :edit, :create, :update, :destroy, :order_minus, :order_plus]

  # Create a theory (show the form)
  def new
    @theory = Theory.new
  end

  # Update a theory (show the form)
  def edit
  end

  # Create a theory (send the form)
  def create
    @theory = Theory.new(:title => params[:theory][:title], :content => params[:theory][:content], :online => false, :chapter => @chapter)
    if @chapter.theories.empty?
      @theory.position = 1
    else
      need = @chapter.theories.order('position').reverse_order.first
      @theory.position = need.position + 1
    end
    if @theory.save
      flash[:success] = "Point théorique ajouté."
      redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
    else
      render 'new'
    end
  end

  # Update a theory (send the form)
  def update
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    if @theory.save
      flash[:success] = "Point théorique modifié."
      redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
    else
      render 'edit'
    end
  end

  # Delete a theory
  def destroy
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end

  # Put a theory online
  def put_online
    @theory.online = true
    @theory.save
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Move a theory up
  def order_minus
    @theory2 = @chapter.theories.where("position < ?", @theory.position).order('position').reverse_order.first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le haut."
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Move a theory down
  def order_plus
    @theory2 = @chapter.theories.where("position > ?", @theory.position).order('position').first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le bas."
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Mark a theory as read
  def read
    current_user.sk.theories << @theory
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Mark a theory as unread
  def unread
    current_user.sk.theories.delete(@theory)
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the theory
  def get_theory
    @theory = Theory.find_by_id(params[:id])
    return if check_nil_object(@theory)
    @chapter = @theory.chapter
  end
  
  # Get the theory (v2)
  def get_theory2
    @theory = Theory.find_by_id(params[:theory_id])
    return if check_nil_object(@theory)
    @chapter = @theory.chapter
  end
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
  end
end

#encoding: utf-8
class TheoriesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order, :put_online, :read, :unread]
  before_action :admin_user, only: [:put_online]
  
  before_action :get_theory, only: [:edit, :update, :destroy]
  before_action :get_theory2, only: [:order, :read, :unread, :put_online]
  before_action :get_chapter, only: [:new, :create]
  
  before_action :user_that_can_update_chapter, only: [:new, :edit, :create, :update, :destroy, :order]

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
      need = @chapter.theories.order('position').last
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
    @theory.update_attribute(:online, true)
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end
  
  # Move a theory to another position
  def order
    theory2 = @chapter.theories.where("position = ?", params[:new_position]).first
    if !theory2.nil? and theory2 != @theory
      res = swap_position(@theory, theory2)
      flash[:success] = "Point théorique déplacé#{res}." 
    end
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

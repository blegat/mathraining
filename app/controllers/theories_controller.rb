#encoding: utf-8
class TheoriesController < ApplicationController
  include ChapterConcern
  
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order, :put_online, :read, :unread]
  before_action :admin_user, only: [:put_online]
  
  before_action :get_theory, only: [:show, :edit, :update, :destroy, :order, :read, :unread, :put_online]
  before_action :get_chapter, only: [:show, :new, :create]
  
  before_action :theory_of_chapter, only: [:show]
  before_action :user_can_see_chapter, only: [:show]
  before_action :user_can_see_theory, only: [:show]
  before_action :user_can_update_chapter, only: [:new, :edit, :create, :update, :destroy, :order]
  
  # Show a theory (inside the chapter)
  def show
  end

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
      redirect_to chapter_theory_path(@chapter, @theory)
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
      redirect_to chapter_theory_path(@chapter, @theory)
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
    redirect_to chapter_theory_path(@chapter, @theory)
  end
  
  # Move a theory to another position
  def order
    theory2 = @chapter.theories.where("position = ?", params[:new_position]).first
    if !theory2.nil? and theory2 != @theory
      res = swap_position(@theory, theory2)
      flash[:success] = "Point théorique déplacé#{res}." 
    end
    redirect_to chapter_theory_path(@chapter, @theory)
  end

  # Mark a theory as read
  def read
    current_user.theories << @theory
    redirect_to chapter_theory_path(@chapter, @theory)
  end

  # Mark a theory as unread
  def unread
    current_user.theories.delete(@theory)
    redirect_to chapter_theory_path(@chapter, @theory)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the theory
  def get_theory
    @theory = Theory.find_by_id(params[:id])
    return if check_nil_object(@theory)
    @chapter = @theory.chapter
  end
  
  # Get the chapter
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    return if check_nil_object(@chapter)
    @section = @chapter.section
  end
  
  ########## CHECK METHODS ##########
  
  # Check that theory belongs to chapter
  def theory_of_chapter
    if @theory.chapter != @chapter
      render 'errors/access_refused'
    end
  end
  
  # Check that user can see the theory
  def user_can_see_theory
    if !@theory.online && !user_can_write_chapter(current_user, @chapter)
      render 'errors/access_refused'
    end
  end
end

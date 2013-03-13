#encoding: utf-8
class TheoriesController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :update, :edit, :new, :create, :order_minus, :order_plus]


  def new
    @theory = Theory.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  def edit
    @theory = Theory.find(params[:id])
  end

  def create
    @theory = Theory.new
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if @chapter.nil?
      flash[:error] = "Chapitre inexistant."
      render 'new' and return
    end
    @theory.chapter = @chapter
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

  def update
    @theory = Theory.find(params[:id])
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    if @theory.save
      flash[:success] = "Point théorique modifié."
      redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
    else
      render 'edit'
    end
  end

  def destroy
    @theory = Theory.find(params[:id])
    @chapter = @theory.chapter
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end
  
  def order_minus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position < ?", @theory.position).order('position').reverse_order.first
    x = @theory.position
    @theory.position = @theory2.position
    @theory2.position = x
    @theory.save(validate: false) # disable validations
    @theory2.save(validate: false) # because position must be unique
    @theory.save
    @theory2.save
    flash[:success] = "Point théorique déplacé vers le haut."
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end
  
  def order_plus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position > ?", @theory.position).order('position').first
    x = @theory.position
    @theory.position = @theory2.position
    @theory2.position = x
    @theory.save(validate: false)
    @theory2.save(validate: false)
    @theory.save
    @theory2.save
    flash[:success] = "Point théorique déplacé vers le bas."
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end
  
  private
  
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
end

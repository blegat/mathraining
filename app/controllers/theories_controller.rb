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
    @theory.chapter_id = params[:chapter_id]
    if Theory.exists?(["chapter_id = ?", params[:chapter_id]])
      need = Theory.where("chapter_id = ?", params[:chapter_id]).order('position').reverse_order.first
      @theory.position = need.position + 1
    else
      @theory.position = 1
    end
    if @theory.save
      flash[:success] = "Point théorique ajouté."
      @chapter = Chapter.find(params[:chapter_id])
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
    @theory2 = Theory.where("position < ? AND chapter_id = ?", @theory.position, @theory.chapter.id).order('position').reverse_order.first
    x = @theory.position
    @theory.position = @theory2.position
    @theory2.position = x
    @theory.save
    @theory2.save
    flash[:success] = "Point théorique déplacé vers le haut."
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end
  
  def order_plus
    @theory = Theory.find(params[:theory_id])
    @theory2 = Theory.where("position > ? AND chapter_id = ?", @theory.position, @theory.chapter.id).order('position').first
    x = @theory.position
    @theory.position = @theory2.position
    @theory2.position = x
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

#encoding: utf-8
class TheoriesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order_minus, :order_plus, :put_online, :read, :unread, :latex]
  before_action :admin_user, only: [:put_online]
  before_action :get_chapter, only: [:new, :create]
  before_action :get_theory, only: [:edit, :update, :destroy]
  before_action :get_theory2, only: [:order_minus, :order_plus, :read, :unread, :latex, :put_online]
  before_action :creating_user, only: [:new, :edit, :create, :update, :destroy, :order_minus, :order_plus]

  # Créer une théorie
  def new
    @theory = Theory.new
  end

  # Editer une théorie
  def edit
  end

  # Créer une théorie 2
  def create
    @theory = Theory.new
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @theory.online = false
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

  # Editer une théorie 2
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

  # Supprimer une théorie
  def destroy
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end

  # Mettre une théorie en ligne
  def put_online
    @theory.online = true
    @theory.save
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Déplacer
  def order_minus
    @theory2 = @chapter.theories.where("position < ?", @theory.position).order('position').reverse_order.first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le haut."
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Déplacer
  def order_plus
    @theory2 = @chapter.theories.where("position > ?", @theory.position).order('position').first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le bas."
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Marquer comme lu
  def read
    current_user.sk.theories << @theory
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Marquer comme non lu
  def unread
    current_user.sk.theories.delete(@theory)
    redirect_to chapter_path(@chapter, :type => 1, :which => @theory.id)
  end

  # Rendre en LaTeX
  def latex
    render text: markdown_to_latex(@theory.content)
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_chapter
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if @chapter.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def get_theory
    @theory = Theory.find_by_id(params[:id])
    if @theory.nil?
      render 'errors/access_refused' and return
    end
    @chapter = @theory.chapter
  end
  
  def get_theory2
    @theory = Theory.find_by_id(params[:theory_id])
    if @theory.nil?
      render 'errors/access_refused' and return
    end
    @chapter = @theory.chapter
  end
  
  def creating_user
    unless (@signed_in && (current_user.sk.admin? || (!@chapter.online? && current_user.sk.creating_chapters.exists?(@chapter.id))))
      render 'errors/access_refused' and return
    end
  end

end

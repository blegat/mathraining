#encoding: utf-8
class TheoriesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :order_minus, :order_plus, :put_online, :read, :unread, :latex]
  before_action :admin_user, only: [:new, :edit, :create, :update, :destroy, :order_minus, :order_plus, :put_online]

  # Créer une théorie
  def new
    @theory = Theory.new
    @chapter = Chapter.find(params[:chapter_id])
  end

  # Editer une théorie
  def edit
    @theory = Theory.find(params[:id])
  end

  # Créer une théorie 2
  def create
    @theory = Theory.new
    @theory.title = params[:theory][:title]
    @theory.content = params[:theory][:content]
    @chapter = Chapter.find(params[:chapter_id])
    if @chapter.nil?
      flash.now[:danger] = "Chapitre inexistant."
      render 'new' and return
    end
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

  # Supprimer une théorie
  def destroy
    @theory = Theory.find(params[:id])
    @chapter = @theory.chapter
    @theory.destroy
    flash[:success] = "Point théorique supprimé."
    redirect_to @chapter
  end

  # Mettre une théorie en ligne
  def put_online
    @theory = Theory.find(params[:theory_id])
    @theory.online = true
    @theory.save
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  # Déplacer
  def order_minus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position < ?", @theory.position).order('position').reverse_order.first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le haut."
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  # Déplacer
  def order_plus
    @theory = Theory.find(params[:theory_id])
    @theory2 = @theory.chapter.theories.where("position > ?", @theory.position).order('position').first
    swap_position(@theory, @theory2)
    flash[:success] = "Point théorique déplacé vers le bas."
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  # Marquer comme lu
  def read
    @theory = Theory.find(params[:theory_id])
    current_user.sk.theories << @theory
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  # Marquer comme non lu
  def unread
    @theory = Theory.find(params[:theory_id])
    current_user.sk.theories.delete(@theory)
    redirect_to chapter_path(@theory.chapter, :type => 1, :which => @theory.id)
  end

  # Rendre en LaTeX
  def latex
    @theory = Theory.find(params[:theory_id])
    render text: markdown_to_latex(@theory.content)
  end

  ########## PARTIE PRIVEE ##########
  private

  def swap_position(a, b)
    x = a.position
    a.position = b.position
    b.position = x
    a.save
    b.save
  end

end

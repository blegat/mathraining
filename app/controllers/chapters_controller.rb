#encoding: utf-8
class ChaptersController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :warning, :read]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online]
  before_action :admin_user, only: [:new, :create, :destroy, :warning, :put_online]
  before_action :get_chapter, only: [:show, :edit, :update, :destroy]
  before_action :get_chapter2, only: [:warning, :put_online, :read]
  before_action :get_section, only: [:new, :create]
  before_action :delete_online, only: [:destroy]
  before_action :online_chapter, only: [:show, :read]
  before_action :prerequisites_online, only: [:warning, :put_online]
  before_action :creating_user, only: [:edit, :update]

  # Voir un chapitre : il faut vérifier que le chapitre est en ligne (ou qu'on est admin)
  def show
  end

  # Créer un chapitre : il faut vérifier que l'on est admin
  def new
    @chapter = Chapter.new
  end

  # Editer un chapitre : il faut vérifier que l'on est admin
  def edit
  end

  # Créer un chapitre 2 : il faut vérifier que l'on est admin
  def create
    @chapter = Chapter.new(params.require(:chapter).permit(:name, :description, :level))
    @chapter.section_id = params[:section_id]
    if @chapter.save
      flash[:success] = "Chapitre ajouté."
      redirect_to chapter_path(@chapter)
    else
      render 'new'
    end
  end

  # Editer un chapitre 2 : il faut vérifier que l'on est admin
  def update
    if @chapter.update_attributes(params.require(:chapter).permit(:name, :description, :level))
      flash[:success] = "Chapitre modifié."
      redirect_to chapter_path(@chapter)
    else
      render 'edit'
    end
  end

  # Supprimer un chapitre : il faut vérifier que l'on est admin (et que le chapitre n'est pas en ligne)
  def destroy
    @chapter.destroy

    Theory.where(:chapter_id => params[:id]).each do |t|
      t.destroy
    end
    
    Question.where(:chapter_id => params[:id]).each do |q|
      Item.where(:question_id => q.id).each do |c|
        c.destroy
      end
      q.destroy
    end
    flash[:success] = "Chapitre supprimé."
    redirect_to section_path(@section)
  end

  # Warning : il faut vérifier qu'on est admin
  def warning
  end

  # Marquer tout le chapitre comme lu : il faut être inscrit et que le chapitre existe et soit en ligne
  def read
    @chapter.theories.each do |t|
      if t.online && !current_user.sk.theories.exists?(t.id)
        current_user.sk.theories << t
      end
    end
    redirect_to chapter_path(@chapter, :type => 10)
  end

  # Mettre en ligne : il faut vérifier qu'on est admin
  def put_online
    @chapter.online = true
    @chapter.save
    @section = @chapter.section
    @chapter.questions.each do |q|
      @section.max_score = @section.max_score + q.value
      q.online = true
      q.save
    end
    @chapter.theories.each do |t|
      t.online = true
      t.save
    end
    @section.save
    redirect_to @chapter
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_chapter
    @chapter = Chapter.find_by_id(params[:id])
    if @chapter.nil?
      render 'errors/access_refused' and return
    end
    @section = @chapter.section
  end
  
  def get_chapter2
    @chapter = Chapter.find_by_id(params[:chapter_id])
    if @chapter.nil?
      render 'errors/access_refused' and return
    end
    @section = @chapter.section
  end
  
  def get_section
    @section = Section.find_by_id(params[:section_id])
    if @section.nil?
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le chapitre est en ligne (ou qu'on est admin)
  def online_chapter
    unless ((@signed_in && (current_user.sk.admin? || current_user.sk.creating_chapters.exists?(@chapter.id))) || @chapter.online)
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le chapitre n'est pas en ligne pour pouvoir le supprimer
  def delete_online
    if @chapter.online
      render 'errors/access_refused' and return
    end
  end

  # Vérifie avant de mettre en ligne que les prérequis sont en ligne
  def prerequisites_online
    @chapter.prerequisites.each do |p|
      if !p.online
        flash[:danger] = "Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne."
        redirect_to @chapter and return
      end
    end
    if @chapter.online
      redirect_to @chapter and return
    end
  end
  
  def creating_user
    unless (@signed_in && (current_user.sk.admin? || (!@chapter.online? && current_user.sk.creating_chapters.exists?(@chapter.id))))
      render 'errors/access_refused' and return
    end
  end

end

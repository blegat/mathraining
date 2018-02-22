#encoding: utf-8
class ChaptersController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :warning, :read]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online]
  before_action :admin_user, only: [:new, :edit, :create, :update, :destroy, :warning, :put_online]
  before_action :chapter_exists1, only: [:show, :edit, :update, :destroy]
  before_action :chapter_exists2, only: [:export, :warning, :put_online, :read]
  before_action :delete_online, only: [:destroy]
  before_action :online_chapter, only: [:show, :export, :read]
  before_action :prerequisites_online, only: [:warning, :put_online]

  # Voir un chapitre : il faut vérifier que le chapitre est en ligne (ou qu'on est admin)
  def show
  end

  # Créer un chapitre : il faut vérifier que l'on est admin
  def new
    @section = Section.find(params[:section_id])
    @chapter = Chapter.new
  end

  # Editer un chapitre : il faut vérifier que l'on est admin
  def edit
  end

  # Créer un chapitre 2 : il faut vérifier que l'on est admin
  def create
    @section = Section.find(params[:section_id])
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
    @chapter = Chapter.find(params[:id])
    @chapter.destroy

    Theory.where(:chapter_id => params[:id]).each do |t|
      t.destroy
    end

    Exercise.where(:chapter_id => params[:id]).each do |e|
      e.destroy
    end

    Qcm.where(:chapter_id => params[:id]).each do |q|
      Choice.where(:qcm_id => q.id).each do |c|
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
      if t.online && !current_user.sk.theories.exists?(t)
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
    @chapter.exercises.each do |e|
      @section.max_score = @section.max_score + e.value
      e.online = true
      e.save
    end
    @chapter.qcms.each do |q|
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

  # Exporter : comme show
  def export
    # Remove spaces and tabs at end of line
    content = @chapter.to_tex.gsub(/[ \t]+$/, "")
    send_data content, filename: "#{@chapter.name}.tex"
  end

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie que le chapitre existe (et le récupère)
  def chapter_exists1
    @chapter = Chapter.find(params[:id])
    @section = @chapter.section
    if @section.fondation?
      @fondation = true
    else
      @fondation = false
    end
    if @chapter.nil?
      redirect_to root_path and return
    end
  end

  # Vérifie que le chapitre existe (et le récupère)
  def chapter_exists2
    @chapter = Chapter.find(params[:chapter_id])
    if @chapter.nil?
      redirect_to root_path and return
    end
  end

  # Vérifie que le chapitre est en ligne (ou qu'on est admin)
  def online_chapter
    redirect_to root_path unless ((signed_in? && current_user.sk.admin?) || @chapter.online)
  end

  # Vérifie que le chapitre n'est pas en ligne pour pouvoir le supprimer
  def delete_online
    redirect_to root_path if @chapter.online
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

end

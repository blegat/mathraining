#encoding: utf-8
class ChaptersController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user,
    only: [:destroy, :edit, :update, :create]
  before_filter :chapter_exists1, only: [:show, :destroy]
  before_filter :chapter_exists2, only:
    [:export, :warning, :put_online]
  before_filter :delete_online, only: [:destroy]
  before_filter :online_chapter,
    only: [:show, :export]
  before_filter :unlocked_chapter,
    only: [:show, :export]
  before_filter :prerequisites_online,
    only: [:warning, :put_online]

  def index
    redirect_to sections_path
  end

  def show
    @ancientexte = session[:ancientexte]
    session[:ancientexte] = nil
  end

  def new
  	@section = Chapter.find(params[:section_id])
    @chapter = Chapter.new
  end

  def edit
    @chapter = Chapter.find(params[:id])
  end

  def create
    @section = Chapter.find(params[:section_id])    
    @chapter = Chapter.new(params[:chapter])
    @chapter.section_id = params[:section_id]
    if @chapter.save
      flash[:success] = "Chapitre ajouté."
      redirect_to chapter_path(@chapter)
    else
      render 'new'
    end
  end

  def update
    @chapter = Chapter.find(params[:id])
    if @chapter.update_attributes(params[:chapter])
      flash[:success] = "Chapitre modifié."
      redirect_to chapter_path(@chapter)
    else
      render 'edit'
    end
  end

  def destroy
    @chapter = Chapter.find(params[:id])
    @chapter.destroy
    flash[:success] = "Chapitre supprimé."
    Exercise.where(:chapter_id => params[:id]).each do |e|
      e.destroy
    end

    Theory.where(:chapter_id => params[:id]).each do |t|
      t.destroy
    end

    Problem.where(:chapter_id => params[:id]).each do |p|
      p.destroy
    end

    Qcm.where(:chapter_id => params[:id]).each do |q|
      Choice.where(:qcm_id => q.id).each do |c|
        c.destroy
      end
      q.destroy
    end

    redirect_to section_path(@section)
  end

  def warning
  end

  def put_online
    @chapter.online = true
    @chapter.save
    redirect_to @chapter
  end

  def export
    # Remove spaces and tabs at end of line
    content = @chapter.to_tex.gsub(/[ \t]+$/, "")
    send_data content, filename: "#{@chapter.name}.tex"
  end

  private
 

  def admin_user
    redirect_to sections_path unless current_user.sk.admin?
  end

  def chapter_exists1
    @chapter = Chapter.find_by_id(params[:id])
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

  def chapter_exists2
    @chapter = Chapter.find(params[:chapter_id])
    if @chapter.nil?
      redirect_to root_path and return
    end
  end

  def online_chapter
    redirect_to sections_path unless (current_user.sk.admin? || @chapter.online)
  end

  def unlocked_chapter
    if !current_user.sk.admin?
      @chapter.prerequisites.each do |p|
        if (p.sections.count > 0 && !current_user.sk.chapters.exists?(p))
          redirect_to sections_path and return
        end
      end
    end
  end

  def delete_online
    redirect_to sections_path if @chapter.online
  end

  def prerequisites_online
    @chapter.prerequisites.each do |p|
      if !p.online
        flash[:error] = "Pour mettre un chapitre en ligne, tous ses prérequis doivent être en ligne."
        redirect_to @chapter and return
      end
    end
    if @chapter.online
      redirect_to @chapter and return
    end
  end

  def point_attribution(user)
    user.point.rating = 0
    partials = user.pointspersections
    partial = Array.new
    partial[0] = partials.where(:section_id => 0).first
    partial[0].points = 0
    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      partial[s.id].points = 0
    end

    user.solvedexercises.each do |e|
      if e.correct
        exo = e.exercise
        if exo.decimal
          pt = 10
        else
          pt = 6
        end

        if !exo.chapter.sections.empty? # Pas un fondement
          user.point.rating = user.point.rating + pt
        else # Fondement
          partial[0].points = partial[0].points + pt
        end

        exo.chapter.sections.each do |s| # Section s
          partial[s.id].points = partial[s.id].points + pt
        end
      end
    end

    user.solvedqcms.each do |q|
      if q.correct
        qcm = q.qcm
        poss = qcm.choices.count
        if qcm.many_answers
          pt = 2*(poss-1)
        else
          pt = poss
        end

        if !qcm.chapter.sections.empty? # Pas un fondement
          user.point.rating = user.point.rating + pt
        else # Fondement
          partial[0].points = partial[0].points + pt
        end

        qcm.chapter.sections.each do |s| # Section s
          partial[s.id].points = partial[s.id].points + pt
        end
      end
    end

    user.solvedproblems.each do |p|
      problem = p.problem
      pt = 25*problem.level

      if !problem.chapter.sections.empty? # Pas un fondement
        user.point.rating = user.point.rating + pt
      else # Fondement
        partial[0].points = partial[0].points + pt
      end

      problem.chapter.sections.each do |s| # Section s
        partial[s.id].points = partial[s.id].points + pt
      end
    end

    user.point.save
    partial[0].save
    Section.all.each do |s|
      partial[s.id].save
    end

  end

end

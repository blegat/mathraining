#encoding: utf-8
class ContestproblemsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :show]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :recup_contest, only: [:new, :create]
  before_action :recup, only: [:show, :edit, :update, :destroy]
  before_action :recup2, only: [:publish_results]
  before_action :is_organizer, only: [:new, :create, :publish_results]
  before_action :is_organizer_or_root, only: [:edit, :update, :destroy]
  before_action :offline_contest, only: [:new, :create, :destroy]
  before_action :check_dates, only: [:create, :update]
  before_action :can_publish_results, only: [:publish_results]
  before_action :has_access, only: [:show]
  
  def show
  end

  # Ajouter un problème
  def new
    @contestproblem = Contestproblem.new
  end
  
  # Editer un problème
  def edit
  end
  
  # Ajouter un problème 2
  def create
    @contestproblem = Contestproblem.new(params.require(:contestproblem).permit(:statement, :origin, :start_time, :end_time))
    if @date_problem
      render 'new' and return
    end
    @contestproblem.contest = @contest
    @contestproblem.number = 1
    if !@contestproblem.save
      render 'new'
    else
      flash[:success] = "Problème ajouté."
      
      official_solution = Contestsolution.new
      official_solution.contestproblem = @contestproblem
      official_solution.user_id = 0
      official_solution.content = "-"
      official_solution.official = true
      official_solution.corrected = true
      official_solution.save
      
      correction = Contestcorrection.new
      correction.contestsolution = official_solution
      correction.content = "-"
      correction.save
      
      change_numbers
      redirect_to @contestproblem
    end
  end
  
  # Editer un problème 2
  def update
    @contestproblem.statement = params[:contestproblem][:statement]
    @contestproblem.origin = params[:contestproblem][:origin]
    if @contestproblem.status <= 1
      @contestproblem.start_time = params[:contestproblem][:start_time]
    end
    if @contestproblem.status <= 2
      @contestproblem.end_time = params[:contestproblem][:end_time]
    end
    if @date_problem
      render 'edit' and return
    end
    if @contestproblem.save
      flash[:success] = "Problème modifié."
      change_numbers
      redirect_to @contestproblem
    else
      render 'edit'
    end
  end
  
  # Supprimer un problème
  def destroy
    @contestproblem.destroy
    flash[:success] = "Problème supprimé."
    redirect_to @contest
  end
  
  def publish_results
    @contestproblem.status = 4
    @contestproblem.save
    
    compute_new_rankings
    
    automatic_results_published_post(@contestproblem)
    
    redirect_to @contestproblem
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def recup
    @contestproblem = Contestproblem.find(params[:id])
    @contest = @contestproblem.contest
  end
  
  def recup2
    @contestproblem = Contestproblem.find(params[:contestproblem_id])
    @contest = @contestproblem.contest
  end
  
  def recup_contest
    @contest = Contest.find(params[:contest_id])
  end
  
  def is_organizer
    if !@contest.is_organized_by(current_user)
      redirect_to @contest
    end
  end
  
  def is_organizer_or_root
    if !@contest.is_organized_by_or_root(current_user)
      redirect_to @contest
    end
  end
  
  def offline_contest
    if @contest.status > 0
      redirect_to @contest
    end
  end
  
  def has_access
    if !@contest.is_organized_by_or_admin(current_user) && @contestproblem.status <= 1
      redirect_to contests_path
    end
  end
  
  def check_dates
    date_now = DateTime.now.in_time_zone
    start_date = nil
    end_date = nil
    if !@contestproblem.nil? && @contestproblem.status >= 2
      start_date = @contestproblem.start_time
    elsif !params[:contestproblem][:start_time].nil?
      start_date = Time.zone.parse(params[:contestproblem][:start_time])
    end
    if !@contestproblem.nil? && @contestproblem.status >= 3
      end_date = @contestproblem.end_time
    elsif !params[:contestproblem][:end_time].nil?
      end_date = Time.zone.parse(params[:contestproblem][:end_time])
    end
    @date_problem = false
    
    if (@contestproblem.nil? || @contestproblem.status <= 2) && !end_date.nil? && date_now >= end_date
      flash.now[:danger] = "La deuxième date ne peut pas être dans le passé."
      @date_problem = true
    end
    if (@contestproblem.nil? || @contestproblem.status <= 1) && !start_date.nil? && date_now >= start_date
      flash.now[:danger] = "La première date ne peut pas être dans le passé."
      @date_problem = true
    end
    if !start_date.nil? && !end_date.nil? && start_date >= end_date
      flash.now[:danger] = "La deuxième date doit être strictement après la première date."
      @date_problem = true
    end
  end
  
  def can_publish_results
    if @contestproblem.status != 3
      flash[:danger] = "Une erreur est survenue."
      redirect_to @contestproblem and return
    end
    if @contestproblem.contestsolutions.where(:star => true).count == 0
      flash[:danger] = "Il faut au minimum une solution étoilée pour publier les résultats."
      redirect_to @contestproblem and return
    end
    if @contestproblem.contestsolutions.where(:corrected => false).count > 0
      flash[:danger] = "Toutes les solutions ne sont pas corrigées."
      redirect_to @contesetproblem and return
    end
  end
  
  def change_numbers
    x = 1
    @contest.contestproblems.order(:start_time, :end_time, :id).each do |p|
      p.number = x
      p.save
      x = x+1
    end
  end
  
  def compute_new_rankings
    userset = Set.new
    probs = @contest.contestproblems.where(:status => 4)
    probs.each do |p|
      p.contestsolutions.where("score > 0 AND official = ?", false).each do |s|
        userset.add(s.user_id)
      end
    end
    scores = Array.new
    userset.each do |u|
      score = 0
      probs.each do |p|
        sol =  p.contestsolutions.where(:user_id => u).first
        if !sol.nil?
          score = score + sol.score
        end
      end
      scores.push([-score, u])
    end
    scores.sort!
    prevscore = -1
    i = 1
    rank = 0
    scores.each do |a|
      score = -a[0]
      u = a[1]
      if score != prevscore
        rank = i
        prevscore = score
      end
      cs = Contestscore.where(:contest => @contest, :user_id => u).first
      if cs.nil?
        cs = Contestscore.new
        cs.contest = @contest
        cs.user_id = u
      end
      cs.rank = rank
      cs.score = score
      cs.save
      i = i+1
    end
  end
  
  def automatic_results_published_post(contestproblem)
    contest = contestproblem.contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0
    text = "Le [url=" + contestproblem_path(contestproblem) + "]Problème ##{contestproblem.number}[/url] du [url=" + contest_url(contest) + "]Concours ##{contest.number}[/url] a été corrigé.\n\r\n\r"
    
    nb_sol = contestproblem.contestsolutions.where("score = 7 AND official = ?", false).count
    
    if nb_sol == 0
      text = text + "Malheureusement [b]personne[/b] n'a obtenu la note maximale !"
    elsif nb_sol == 1
      text = text + "Seule [b]une seule[/b] personne a obtenu la note maximale : "
    else
      text = text + "Les [b]" + nb_sol.to_s + "[/b] personnes suivantes ont obtenu la note maximale : "
    end
    
    i = 0
    contestproblem.contestsolutions.where("score = 7 AND official = ?", false).order(:user_id).each do |s|
      text = text + s.user.name
      i = i+1
      if (i == nb_sol)
        text = text + "."
      elsif (i == nb_sol - 1)
        text = text + " et "
      else
        text = text + ", "
      end
    end
    
    text = text + "\n\r\n\r"
    if contest.contestproblems.where("status < 4").count > 0
      text = text + "Le nouveau classement général suite à cette correction peut être consulté sur la page du concours."    
    else
      text = text + "Il s'agissait du dernier problème. Le classement final peut être consulté sur la page du concours."    
    end
    
    mes.content = text
    mes.save
    sub.lastcomment = mes.created_at
    sub.save
  end

end

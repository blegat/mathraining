#encoding: utf-8
class ContestproblemsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :show]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :publish_results, :authorize_corrections, :unauthorize_corrections]
  before_action :root_user, only: [:authorize_corrections, :unauthorize_corrections]
  before_action :check_contests, only: [:show] # Defined in application_controller.rb
  before_action :get_contest, only: [:new, :create]
  before_action :get_contestproblem, only: [:show, :edit, :update, :destroy]
  before_action :get_contestproblem2, only: [:publish_results, :authorize_corrections, :unauthorize_corrections]
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
    
    compute_new_contest_rankings(@contest)
    
    automatic_results_published_post(@contestproblem)
    
    redirect_to @contestproblem
  end
  
  def authorize_corrections
    if @contestproblem.status == 4
      @contestproblem.status = 5
      @contestproblem.save
      flash[:success] = "Les organisateurs peuvent à présent modifier leurs corrections. N'oubliez pas de stopper cette autorisation temporaire quand ils ont terminé !"      
    end      
    redirect_to @contestproblem
  end
  
  def unauthorize_corrections
    if @contestproblem.status == 5
      @contestproblem.status = 4
      @contestproblem.save
      flash[:success] = "Les organisateurs ne peuvent plus modifier leurs corrections."
    end      
    redirect_to @contestproblem
  end

  ########## PARTIE PRIVEE ##########
  private
  
  def get_contestproblem
    @contestproblem = Contestproblem.find_by_id(params[:id])
    if @contestproblem.nil?
      render 'errors/access_refused' and return
    end
    @contest = @contestproblem.contest
  end
  
  def get_contestproblem2
    @contestproblem = Contestproblem.find_by_id(params[:contestproblem_id])
    if @contestproblem.nil?
      render 'errors/access_refused' and return
    end
    @contest = @contestproblem.contest
  end
  
  def get_contest
    @contest = Contest.find_by_id(params[:contest_id])
    if @contest.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def is_organizer
    if !@contest.is_organized_by(current_user)
      render 'errors/access_refused' and return
    end
  end
  
  def is_organizer_or_root
    if !@contest.is_organized_by_or_root(current_user)
      render 'errors/access_refused' and return
    end
  end
  
  def offline_contest
    if @contest.status > 0
      render 'errors/access_refused' and return
    end
  end
  
  def has_access
    if !@contest.is_organized_by_or_admin(current_user) && @contestproblem.status <= 1
      render 'errors/access_refused' and return
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
    if start_date.min != 0
      if Rails.env.production?
        flash.now[:danger] = "La première date doit être à une heure pile."
        @date_problem = true
      else
        flash[:info] = "La première date devrait être à une heure pile (en production)."
      end
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
      redirect_to @contestproblem and return
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
    sub.lastcomment_user_id = 0 # Message automatique
    sub.save
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver if Rails.env.production?
    end
  end

end

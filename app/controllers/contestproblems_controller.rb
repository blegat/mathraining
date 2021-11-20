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
      
      update_contest_details
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
      update_contest_details
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
    update_contest_details
    change_numbers
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
    return if check_nil_object(@contestproblem)
    @contest = @contestproblem.contest
  end
  
  def get_contestproblem2
    @contestproblem = Contestproblem.find_by_id(params[:contestproblem_id])
    return if check_nil_object(@contestproblem)
    @contest = @contestproblem.contest
  end
  
  def get_contest
    @contest = Contest.find_by_id(params[:contest_id])
    return if check_nil_object(@contest)
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
    elsif (@contestproblem.nil? || @contestproblem.status <= 1) && !start_date.nil? && date_now >= start_date
      flash.now[:danger] = "La première date ne peut pas être dans le passé."
      @date_problem = true
    elsif !start_date.nil? && !end_date.nil? && start_date >= end_date
      flash.now[:danger] = "La deuxième date doit être strictement après la première date."
      @date_problem = true
    elsif start_date.min != 0
      if !Rails.env.development?
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
  
  def update_contest_details
    @contest.num_problems = @contest.contestproblems.count
    if @contest.num_problems > 0
      @contest.start_time = @contest.contestproblems.order(:start_time).first.start_time
      @contest.end_time = @contest.contestproblems.order(:end_time).last.end_time
    else
      @contest.start_time = nil
      @contest.end_time = nil
    end
    @contest.save
  end
  
  def automatic_results_published_post(contestproblem)
    contest = contestproblem.contest
    sub = contest.subject
    mes = Message.new
    mes.subject = sub
    mes.user_id = 0    
    mes.content = helpers.get_new_correction_forum_message(contest, contestproblem)
    mes.save
    sub.lastcomment = mes.created_at
    sub.lastcomment_user_id = 0 # Message automatique
    sub.save
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver if Rails.env.production?
    end
  end

end

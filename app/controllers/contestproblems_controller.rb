#encoding: utf-8
class ContestproblemsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit, :show]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :publish_results, :authorize_corrections, :unauthorize_corrections]
  before_action :root_user, only: [:authorize_corrections, :unauthorize_corrections]
  
  before_action :check_contests, only: [:show] # Defined in application_controller.rb
  
  before_action :get_contest, only: [:new, :create]
  before_action :get_contestproblem, only: [:show, :edit, :update, :destroy]
  before_action :get_contestproblem2, only: [:publish_results, :authorize_corrections, :unauthorize_corrections]
  
  before_action :organizer_of_contest, only: [:new, :create, :publish_results]
  before_action :organizer_of_contest_or_root, only: [:edit, :update, :destroy]
  before_action :offline_contest, only: [:new, :create, :destroy]
  before_action :check_dates, only: [:create, :update]
  before_action :can_publish_results, only: [:publish_results]
  before_action :has_access, only: [:show]
  
  # Show a problem of a contest
  def show
  end

  # Create a problem (show the form)
  def new
    @contestproblem = Contestproblem.new
  end
  
  # Update a problem (show the form)
  def edit
  end
  
  # Create a problem (send the form)
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
      
      @contest.update_details
      @contest.update_problem_numbers
      redirect_to @contestproblem
    end
  end
  
  # Update a problem (send the form)
  def update
    @contestproblem.statement = params[:contestproblem][:statement]
    @contestproblem.origin = params[:contestproblem][:origin]
    if @contestproblem.at_most(:not_started_yet)
      @contestproblem.start_time = params[:contestproblem][:start_time]
    end
    if @contestproblem.at_most(:in_progress)
      @contestproblem.end_time = params[:contestproblem][:end_time]
    end
    if @date_problem
      render 'edit' and return
    end
    if @contestproblem.save
      flash[:success] = "Problème modifié."
      @contest.update_details
      @contest.update_problem_numbers
      redirect_to @contestproblem
    else
      render 'edit'
    end
  end
  
  # Delete a problem
  def destroy
    @contestproblem.destroy
    flash[:success] = "Problème supprimé."
    @contest.update_details
    @contest.update_problem_numbers
    redirect_to @contest
  end
  
  # Publish results of a problem
  def publish_results
    @contestproblem.corrected!
    
    compute_new_contest_rankings(@contest)
    
    automatic_results_published_post(@contestproblem)
    
    redirect_to @contestproblem
  end
  
  # Temporarily authorize new corrections for a problem that is already corrected
  def authorize_corrections
    if @contestproblem.corrected?
      @contestproblem.in_recorrection!
      flash[:success] = "Les organisateurs peuvent à présent modifier leurs corrections. N'oubliez pas de stopper cette autorisation temporaire quand ils ont terminé !"      
    end      
    redirect_to @contestproblem
  end
  
  # Stop authorizing new corrections for a problem
  def unauthorize_corrections
    if @contestproblem.in_recorrection?
      @contestproblem.corrected!
      flash[:success] = "Les organisateurs ne peuvent plus modifier leurs corrections."
    end      
    redirect_to @contestproblem
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the problem
  def get_contestproblem
    @contestproblem = Contestproblem.find_by_id(params[:id])
    return if check_nil_object(@contestproblem)
    @contest = @contestproblem.contest
  end
  
  # Get the problem (v2)
  def get_contestproblem2
    @contestproblem = Contestproblem.find_by_id(params[:contestproblem_id])
    return if check_nil_object(@contestproblem)
    @contest = @contestproblem.contest
  end
  
  # Get the contest
  def get_contest
    @contest = Contest.find_by_id(params[:contest_id])
    return if check_nil_object(@contest)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the contest is offline
  def offline_contest
    if !@contest.in_construction?
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user has access to the problem
  def has_access
    if !@contest.is_organized_by_or_admin(current_user.sk) && @contestproblem.at_most(:not_started_yet)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the dates in the form are suitable
  def check_dates
    date_now = DateTime.now.in_time_zone
    start_date = nil
    end_date = nil
    if !@contestproblem.nil? && @contestproblem.at_least(:in_progress)
      start_date = @contestproblem.start_time
    elsif !params[:contestproblem][:start_time].nil?
      start_date = Time.zone.parse(params[:contestproblem][:start_time])
    end
    if !@contestproblem.nil? && @contestproblem.at_least(:in_correction)
      end_date = @contestproblem.end_time
    elsif !params[:contestproblem][:end_time].nil?
      end_date = Time.zone.parse(params[:contestproblem][:end_time])
    end
    @date_problem = false
    
    if (start_date.nil? or end_date.nil?)
      flash.now[:danger] = "Les deux dates doivent être définies."
      @date_problem = true
    elsif (@contestproblem.nil? || @contestproblem.at_most(:in_progress)) && !end_date.nil? && date_now >= end_date
      flash.now[:danger] = "La deuxième date ne peut pas être dans le passé."
      @date_problem = true
    elsif (@contestproblem.nil? || @contestproblem.at_most(:not_started_yet)) && !start_date.nil? && date_now >= start_date
      flash.now[:danger] = "La première date ne peut pas être dans le passé."
      @date_problem = true
    elsif !start_date.nil? && !end_date.nil? && start_date >= end_date
      flash.now[:danger] = "La deuxième date doit être strictement après la première date."
      @date_problem = true
    elsif start_date.min != 0
      flash.now[:danger] = "La première date doit être à une heure pile#{ '(en production)' if Rails.env.development?}."
      @date_problem = true if !Rails.env.development?
    end
  end
  
  # Check if results of the problem can be published
  def can_publish_results
    if !@contestproblem.in_correction?
      flash[:danger] = "Une erreur est survenue."
      redirect_to @contestproblem and return
    end
    if @contestproblem.contestsolutions.where(:corrected => false).count > 0
      flash[:danger] = "Les solutions ne sont pas toutes corrigées."
      redirect_to @contestproblem and return
    end
    if @contestproblem.contestsolutions.where(:star => true).count == 0
      flash[:danger] = "Il faut au minimum une solution étoilée pour publier les résultats."
      redirect_to @contestproblem and return
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to create automatic message on forum to say that results have been published
  def automatic_results_published_post(contestproblem)
    contest = contestproblem.contest
    sub = contest.subject
    mes = Message.create(:subject => sub, :user_id => 0, :content => helpers.get_new_correction_forum_message(contest, contestproblem))
    sub.update(:last_comment_time    => mes.created_at,
               :last_comment_user_id => 0) # Automatic message
    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver
    end
  end

end

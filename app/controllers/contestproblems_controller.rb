#encoding: utf-8
class ContestproblemsController < ApplicationController
  include ContestConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!

  before_action :signed_in_user, only: [:new, :edit, :show]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :publish_results, :authorize_corrections, :unauthorize_corrections]
  before_action :root_user, only: [:authorize_corrections, :unauthorize_corrections]
  
  before_action :check_contests, only: [:show]
  
  before_action :get_contest, only: [:new, :create]
  before_action :get_contestproblem, only: [:show, :edit, :update, :destroy, :publish_results, :authorize_corrections, :unauthorize_corrections]
  
  before_action :organizer_of_contest, only: [:new, :create, :publish_results]
  before_action :organizer_of_contest_or_root, only: [:edit, :update, :destroy]
  before_action :offline_contest, only: [:new, :create, :destroy]
  before_action :check_dates, only: [:create, :update]
  before_action :can_publish_results, only: [:publish_results]
  before_action :has_access, only: [:show]
  
  # Show a problem of a contest
  def show
    if signed_in? && @contestproblem.in_progress? && has_enough_points(current_user) && !@contest.is_organized_by_or_admin(current_user)
      @contestsolution = @contestproblem.contestsolutions.where(:user => current_user).first
      @contestsolution = Contestsolution.new if @contestsolution.nil?
    elsif params.has_key?(:sol)
      @contestsolution = Contestsolution.find_by_id(params[:sol].to_i)
    end
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
    @contestproblem.contest = @contest
    @contestproblem.number = 1
    
    # Invalid CSRF token
    render_with_error('contestproblems/new', @contestproblem, get_csrf_error_message) and return if @invalid_csrf_token
    
    # Invalid dates
    render_with_error('contestproblems/new', @contestproblem, @date_error) and return if !@date_error.nil?

    # Invalid contestproblem
    render_with_error('contestproblems/new') and return if !@contestproblem.save
    
    flash[:success] = "Problème ajouté."
      
    @contest.update_details
    @contest.update_problem_numbers
    redirect_to @contestproblem
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
    
    # Invalid CSRF token
    render_with_error('contestproblems/edit', @contestproblem, get_csrf_error_message) and return if @invalid_csrf_token
    
    # Invalid dates
    render_with_error('contestproblems/edit', @contestproblem, @date_error) and return if !@date_error.nil?
    
    # Invalid contestproblem
    render_with_error('contestproblems/edit') and return if !@contestproblem.save
    
    flash[:success] = "Problème modifié."
    
    @contest.update_details
    @contest.update_problem_numbers
    redirect_to @contestproblem
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
    
    @contest.compute_new_contest_rankings
    
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
    if !@contest.is_organized_by_or_admin(current_user) && @contestproblem.at_most(:not_started_yet)
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
    
    if (start_date.nil? or end_date.nil?)
      @date_error = "Les deux dates doivent être définies."
    elsif (@contestproblem.nil? || @contestproblem.at_most(:in_progress)) && !end_date.nil? && date_now >= end_date
      @date_error = "La deuxième date ne peut pas être dans le passé."
    elsif (@contestproblem.nil? || @contestproblem.at_most(:not_started_yet)) && !start_date.nil? && date_now >= start_date
      @date_error = "La première date ne peut pas être dans le passé."
    elsif !start_date.nil? && !end_date.nil? && start_date >= end_date
      @date_error = "La deuxième date doit être strictement après la première date."
    elsif start_date.min != 0
      date_error = "La première date doit être à une heure pile#{ ' (en production)' if Rails.env.development?}."
      @date_error = date_error unless Rails.env.development?
      flash[:info] = date_error if Rails.env.development?
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
    Message.create(:subject => sub, :user_id => 0, :content => helpers.get_new_correction_forum_message(contest, contestproblem))    
    sub.following_users.each do |u|
      UserMailer.new_followed_message(u.id, sub.id, -1).deliver
    end
  end
end

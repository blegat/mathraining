#encoding: utf-8
class ContestsolutionsController < ApplicationController
  include ContestConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :reserve, :unreserve]
  
  before_action :check_contests, only: [:create, :update, :destroy]
  
  before_action :get_contestsolution, only: [:update, :destroy, :reserve, :unreserve]
  before_action :get_contestproblem, only: [:create]
  
  before_action :user_can_send_solution, only: [:create, :update]
  before_action :user_can_write_submission, only: [:create]
  before_action :user_can_delete_solution, only: [:destroy]
  before_action :organizer_of_contest, only: [:reserve, :unreserve]
  before_action :solution_can_be_reserved, only: [:reserve, :unreserve]

  # Create a solution (send the form)
  def create
    if @send_solution == 2 # Can happen if we have two windows and we try to create twice a solution to a same problem
      update and return
    end
  
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?

    @contestsolution = @contestproblem.contestsolutions.build(content: params[:contestsolution][:content],
                                                              user:    current_user)
    
    # Invalid CSRF token
    render_with_error('contestproblems/show', @contestsolution, get_csrf_error_message) and return if @invalid_csrf_token
    
    # Invalid contestsolution
    render_with_error('contestproblems/show') and return if !@contestsolution.valid? 
    
    # Attached files
    attach = create_files
    render_with_error('contestproblems/show', @contestsolution, @file_error) and return if !@file_error.nil?

    @contestsolution.save

    attach_files(attach, @contestsolution)
    flash[:success] = "Solution enregistrée."
    redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
  end

  # Update a solution (send the form)
  def update
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?
    @contestsolution.content = params[:contestsolution][:content]
    
    # Invalid CSRF token
    render_with_error('contestproblems/show', @contestsolution, get_csrf_error_message) and return if @invalid_csrf_token

    # Invalid contestsolution
    render_with_error('contestproblems/show') and return if !@contestsolution.valid? 

    # Attached files
    update_files(@contestsolution)
    render_with_error('contestproblems/show', @contestsolution, @file_error) and return if !@file_error.nil?
    
    @contestsolution.save
    
    flash[:success] = "Solution enregistrée."
    redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
  end

  # Delete a solution
  def destroy
    flash[:success] = "Solution supprimée."
    @contestsolution.destroy
    redirect_to contestproblem_path(@contestproblem)
  end
  
  # Reserve a solution
  def reserve
    if @contestsolution.reservation > 0 and @contestsolution.reservation != current_user.id
      @correct_name = User.find(@contestsolution.reservation).name
      @ok = 0
    else
      @contestsolution.update_attribute(:reservation, current_user.id)
      @ok = 1
    end
  end

  # Un-reserve a solution
  def unreserve
    @contestsolution.update_attribute(:reservation, 0)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the solution
  def get_contestsolution
    @contestsolution = Contestsolution.find_by_id(params[:id])
    return if check_nil_object(@contestsolution)
    @contestproblem = @contestsolution.contestproblem
    @contest = @contestproblem.contest
  end

  # Get the problem
  def get_contestproblem
    @contestproblem = Contestproblem.find_by_id(params[:contestproblem_id])
    return if check_nil_object(@contestproblem)
    @contest = @contestproblem.contest
  end
  
  ########## CHECK METHODS ##########
  
  # Check if current user can send a solution
  def user_can_send_solution
    @send_solution = 0 # Cannot send a solution
    mycontestsolution = nil
    if !@contest.is_organized_by_or_admin(current_user) && @contestproblem.in_progress?
      mycontestsolution = @contestproblem.contestsolutions.where(:user => current_user).first
      if !mycontestsolution.nil?
        @send_solution = 2 # A solution already exists
      elsif current_user.rating >= 200
        @send_solution = 1 # No solution exists and user has >= 200 points
      end
    end
    
    if @send_solution == 0
      flash[:danger] = "Vous ne pouvez pas enregistrer cette solution."
      redirect_to @contestproblem
    elsif @send_solution == 2
      if @contestsolution.nil? # Can happen in "create" case when a solution was sent in the meantime
        @contestsolution = mycontestsolution
      elsif mycontestsolution != @contestsolution
        render 'errors/access_refused' and return
      end
    end
  end
  
  # Check if current user can delete a solution
  def user_can_delete_solution
    unless @contestproblem.in_progress? && !@contestsolution.official && @contestsolution.user == current_user && !in_skin?
      flash[:danger] = "Vous ne pouvez pas supprimer cette solution."
      redirect_to @contestproblem
    end
  end
  
  # Check if the solution can be reserved
  def solution_can_be_reserved
    if !@contestproblem.in_correction? && !@contestproblem.in_recorrection? && !@contestsolution.official?
      redirect_to @contestproblem
    end
  end
end

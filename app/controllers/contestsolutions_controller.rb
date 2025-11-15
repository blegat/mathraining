#encoding: utf-8
class ContestsolutionsController < ApplicationController
  include ContestConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :reserve, :unreserve]
  
  before_action :check_contests, only: [:create, :update, :destroy]
  
  before_action :get_contestsolution, only: [:show, :update, :destroy, :reserve, :unreserve]
  before_action :get_contestproblem, only: [:show, :create]
  
  before_action :contestsolution_of_contestproblem, only: [:show]
  before_action :user_can_see_solution, only: [:show]
  before_action :author_of_solution, only: [:update]
  before_action :user_can_send_solution, only: [:create, :update]
  before_action :user_can_write_submission, only: [:create]
  before_action :user_can_delete_solution, only: [:destroy]
  before_action :organizer_of_contest, only: [:reserve, :unreserve]
  before_action :solution_can_be_reserved, only: [:reserve, :unreserve]
  
  # Show a solution
  def show
  end

  # Create a solution (send the form)
  def create
    oldsol = @contestproblem.contestsolutions.where(:user => current_user).first
    if !oldsol.nil? # Can happen if we have two windows and we try to create twice a solution to a same problem
      @contestsolution = oldsol
      update and return
    end
  
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?

    @contestsolution = @contestproblem.contestsolutions.build(content: params[:contestsolution][:content],
                                                              user:    current_user)
    
    # Save solution, handling usual errors
    if !save_object_handling_errors(@contestsolution, 'contestproblems/show')
      return
    end
    
    flash[:success] = "Solution enregistrée."
    redirect_to contestproblem_contestsolution_path(@contestproblem, @contestsolution)
  end

  # Update a solution (send the form)
  def update
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?
    @contestsolution.content = params[:contestsolution][:content]
    
    # Save solution, handling usual errors
    if !save_object_handling_errors(@contestsolution, 'contestproblems/show')
      return
    end
    
    flash[:success] = "Solution enregistrée."
    redirect_to contestproblem_contestsolution_path(@contestproblem, @contestsolution)
  end

  # Delete a solution
  def destroy
    flash[:success] = "Solution supprimée."
    @contestsolution.destroy
    redirect_to contestproblem_path(@contestproblem)
  end
  
  # Reserve a solution
  def reserve
    if @contestsolution.reservation > 0 && @contestsolution.reservation != current_user.id
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
  
  # Check that solution belongs to problem
  def contestsolution_of_contestproblem
    if @contestsolution.contestproblem != @contestproblem
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is the author of the solution
  def author_of_solution
    if @contestsolution.user != current_user
      render 'errors/access_refused'
    end
  end
  
  # Check if current user can see a solution
  def user_can_see_solution
    if !signed_in? || !@contestsolution.can_be_seen_by(current_user)
      redirect_to contestproblem_path(@contestproblem)
    end
  end
  
  # Check if current user can send a solution
  def user_can_send_solution
    if @contest.is_organized_by_or_admin(current_user) || current_user.rating < 200 || @contestproblem.at_most(:not_started_yet)
      render 'errors/access_refused' and return
    end
    if !@contestproblem.in_progress?
      flash[:danger] = "Vous ne pouvez plus enregistrer cette solution."
      redirect_to @contestproblem
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

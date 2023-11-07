#encoding: utf-8
class ContestsolutionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :reserve, :unreserve]
  
  before_action :check_contests, only: [:create, :update, :destroy] # Defined in application_controller.rb
  
  before_action :get_contestsolution, only: [:update, :destroy]
  before_action :get_contestsolution2, only: [:reserve, :unreserve]
  before_action :get_contestproblem, only: [:create]
  
  before_action :can_send_solution, only: [:create, :update]
  before_action :user_that_can_write_submission, only: [:create]
  before_action :can_delete_solution, only: [:destroy]
  before_action :organizer_of_contest, only: [:reserve, :unreserve]
  before_action :can_reserve, only: [:reserve, :unreserve]

  # Create a solution (send the form)
  def create
    if @send_solution == 2 # Can happen if we have two windows and we try to create twice a solution to a same problem
      update and return
    end
  
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?
    
    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      flash[:danger] = @error_message
      session[:ancientexte] = params[:contestsolution][:content]
      redirect_to contestproblem_path(@contestproblem) and return
    end

    solution = @contestproblem.contestsolutions.build(content: params[:contestsolution][:content])
    solution.user = current_user.sk

    if solution.save
      attach_files(attach, solution)
      flash[:success] = "Solution enregistrée."
      redirect_to contestproblem_path(@contestproblem, :sol => solution)
    else
      destroy_files(attach)
      session[:ancientexte] = params[:contestsolution][:content]
      flash[:danger] = error_list_for(solution)
      redirect_to contestproblem_path(@contestproblem)
    end
  end

  # Update a solution (send the form)
  def update
    params[:contestsolution][:content].strip! if !params[:contestsolution][:content].nil?
    @contestsolution.content = params[:contestsolution][:content]
    if @contestsolution.valid?
    
      # Attached files
      @error_message = ""
      update_files(@contestsolution)
      if !@error_message.empty?
        flash[:danger] = @error_message
        session[:ancientexte] = params[:contestsolution][:content]
        redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution) and return
      end
      
      @contestsolution.save
      flash[:success] = "Solution enregistrée."
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    else
      session[:ancientexte] = params[:contestsolution][:content]
      flash[:danger] = error_list_for(@contestsolution)
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    end
  end

  # Delete a solution
  def destroy
    flash[:success] = "Solution supprimée."
    @contestsolution.destroy
    redirect_to contestproblem_path(@contestproblem)
  end
  
  # Reserve a solution
  def reserve
    if @contestsolution.reservation > 0 and @contestsolution.reservation != current_user.sk.id
      @correct_name = User.find(@contestsolution.reservation).name
      @ok = 0
    else
      @contestsolution.reservation = current_user.sk.id
      @contestsolution.save
      @ok = 1
    end
  end

  # Un-reserve a solution
  def unreserve
    @contestsolution.reservation = 0
    @contestsolution.save
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
  
  # Get the solution (v2)
  def get_contestsolution2
    @contestsolution = Contestsolution.find_by_id(params[:contestsolution_id])
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
  def can_send_solution
    @send_solution = 0 # Cannot send a solution
    mycontestsolution = nil
    if !@contest.is_organized_by_or_admin(current_user.sk) && @contestproblem.in_progress?
      mycontestsolution = @contestproblem.contestsolutions.where(:user => current_user.sk).first
      if !mycontestsolution.nil?
        @send_solution = 2 # A solution already exists
      elsif current_user.sk.rating >= 200
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
  def can_delete_solution
    unless @contestproblem.in_progress? && !@contestsolution.official && @contestsolution.user == current_user.sk && !current_user.other
      flash[:danger] = "Vous ne pouvez pas supprimer cette solution."
      redirect_to @contestproblem
    end
  end
  
  # Check if the solution can be reserved
  def can_reserve
    if !@contestproblem.in_correction? && !@contestproblem.in_recorrection? && !@contestsolution.official?
      redirect_to @contestproblem
    end
  end
end

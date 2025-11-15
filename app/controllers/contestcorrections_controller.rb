#encoding: utf-8
class ContestcorrectionsController < ApplicationController
  include ContestConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:update] # Do not forget to check @invalid_csrf_token instead!
  
  before_action :signed_in_user_danger, only: [:update]
  
  before_action :get_contestcorrection, only: [:update]
  
  before_action :organizer_of_contest, only: [:update]
  before_action :user_can_update_correction, only: [:update]
  before_action :user_has_reserved_solution, only: [:update]

  # Update a correction (send the form)
  def update    
    params[:contestcorrection][:content].strip! if !params[:contestcorrection][:content].nil?
    @contestcorrection.content = params[:contestcorrection][:content]
    
    # Save correction, handling usual errors
    if !save_object_handling_errors(@contestcorrection, 'contestsolutions/show')
      return
    end
    
    old_score = @contestsolution.score
    
    if !@contestsolution.official?
      @contestsolution.score = params["score".to_sym].to_i
    end
    
    @contestsolution.reservation = 0
    
    if params[:status] == "bad"
      if @contestsolution.official?
        @contestsolution.corrected = true
        @contestsolution.star = false
        @contestsolution.score = 0
      end
    elsif params[:status] == "good"
      @contestsolution.corrected = true
      @contestsolution.star = false
      if @contestsolution.official?
        @contestsolution.score = 7
      end
    elsif params[:status] == "star"
      @contestsolution.corrected = true
      @contestsolution.star = true
      if @contestsolution.official?
        @contestsolution.score = 7
      else
        if @contestsolution.score < 7
          @contestsolution.score = 7
          flash[:info] = "Le score a été mis automatiquement à 7/7 (car solution étoilée)."
        end
      end
    elsif params[:status] == "unknown"
      if !@contestsolution.official?
        @contestsolution.corrected = false
        @contestsolution.star = false
      end
    end
    
    @contestsolution.save
    
    if @contestproblem.in_recorrection? && @contestsolution.score != old_score
      @contest.compute_new_contest_rankings
    end
    
    if @contestsolution.official?
      flash[:success] = "Solution enregistrée."
    else
      flash[:success] = "Correction enregistrée."
    end
    
    redirect_to contestproblem_contestsolution_path(@contestproblem, @contestsolution)
  end

  private
  
  ########## GET METHODS ##########

  # Get the correction
  def get_contestcorrection
    @contestcorrection = Contestcorrection.find_by_id(params[:id])
    return if check_nil_object(@contestcorrection)
    @contestsolution = @contestcorrection.contestsolution
    @contestproblem = @contestsolution.contestproblem
    @contest = @contestproblem.contest
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the correction can be updated
  def user_can_update_correction
    if !@contestproblem.in_correction? && !@contestproblem.in_recorrection? && !@contestsolution.official
      flash[:danger] = "Vous ne pouvez pas modifier cette correction."
      redirect_to contestproblem_contestsolution_path(@contestproblem, @contestsolution)
    end
  end
  
  # Check that current user has reserved the solution
  def user_has_reserved_solution
    if @contestsolution.reservation != current_user.id
      flash[:danger] = "Vous n'avez pas réservé."
      redirect_to contestproblem_contestsolution_path(@contestproblem, @contestsolution)
    end
  end
end

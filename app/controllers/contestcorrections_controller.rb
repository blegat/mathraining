#encoding: utf-8
class ContestcorrectionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:update]
  before_action :get_contestcorrection, only: [:update]
  before_action :is_organizer, only: [:update]
  before_action :can_update_correction, only: [:update]
  before_action :has_reserved, only: [:update]

  # Modifier une correction
  def update  
    if @send_solution == 1 # Not normal
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    end
    
    params[:contestcorrection][:content].strip! if !params[:contestcorrection][:content].nil?
    @contestcorrection.content = params[:contestcorrection][:content]
    if @contestcorrection.valid?
    
      # Pièces jointes
      @error = false
      @error_message = ""
      
      update_files(@contestcorrection) # Fonction commune pour toutes les pièces jointes

      if @error
        flash[:danger] = @error_message
        session[:ancientexte] = params[:contestcorrection][:content]
        redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution) and return
      end
      
      @contestcorrection.save
      
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
      
      if @contestproblem.status == 5 && @contestsolution.score != old_score
        compute_new_contest_rankings(@contest)
      end
      
      if @contestsolution.official?
        flash[:success] = "Solution enregistrée."
      else
        flash[:success] = "Correction enregistrée."
      end
      
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    else
      session[:ancientexte] = params[:contestcorrection][:content]
      flash[:danger] = error_list_for(@contestcorrection)
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    end
  end

  ########## PARTIE PRIVEE ##########
  private

  def get_contestcorrection
    @contestcorrection = Contestcorrection.find_by_id(params[:id])
    return if check_nil_object(@contestcorrection)
    @contestsolution = @contestcorrection.contestsolution
    @contestproblem = @contestsolution.contestproblem
    @contest = @contestproblem.contest
  end
  
  def is_organizer
    if !@contest.is_organized_by(current_user)
      render 'errors/access_refused' and return
    end
  end
  
  def can_update_correction
    if @contestproblem.status != 3 && @contestproblem.status != 5 && !@contestsolution.official
      flash[:danger] = "Vous ne pouvez pas modifier cette correction."
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    end
  end
  
  def has_reserved
    if @contestsolution.reservation != current_user.sk.id
      flash[:danger] = "Vous n'avez pas réservé."
      redirect_to contestproblem_path(@contestproblem, :sol => @contestsolution)
    end
  end
end

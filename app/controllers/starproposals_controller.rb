#encoding: utf-8
class StarproposalsController < ApplicationController
  before_action :corrector_user, only: [:index]
  before_action :root_user, only: [:destroy, :update]
  before_action :get_starproposal, only: [:destroy, :update]
  before_action :get_submission, only: [:create]
  before_action :user_that_can_correct_submission, only: [:create]
  before_action :correct_submission, only: [:create, :update]

  # Show all star proposals (or only the ones that are not treated yet)
  def index
    if current_user.sk.root?
      if params.has_key?:show_all
        # Show all star proposals
        @starproposals = Starproposal.joins(:submission).joins(submission: [{ problem: :section }]).select("starproposals.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).all.order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
      else
        # Show star proposals waiting for confirmation
        @starproposals = Starproposal.joins(:submission).joins(submission: [{ problem: :section }]).select("starproposals.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).where(:status => :waiting_treatment).order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
      end
    else
      # Show all my star proposals
      @starproposals = current_user.sk.starproposals.joins(:submission).joins(submission: [{ problem: :section }]).select("starproposals.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
    end
  end
  
  # Delete a star proposal
  def destroy
    @starproposal.destroy
    flash[:success] = "Proposition d'étoile supprimée."
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end
  
  # Create a star proposal
  def create
    params[:starproposal][:reason].strip! if !params[:starproposal][:reason].nil?
    starproposal = Starproposal.new(:user => current_user.sk, :submission => @submission, :reason => params[:starproposal][:reason], :answer => "", :status => :waiting_treatment)
    if starproposal.save
      flash[:success] = "Proposition d'étoile envoyée."
    else
      flash[:danger] = error_list_for(starproposal)
    end
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end
  
  # Update a star proposal (for example its status, to confirm it)
  def update
    params[:starproposal][:answer].strip! if !params[:starproposal][:answer].nil?
    old_status = @starproposal.status
    if @starproposal.update(params.require(:starproposal).permit(:answer, :status))
      if params[:starproposal][:status] == "accepted"
        @submission.update_attribute(:star, true)
      end
      flash[:success] = "Proposition d'étoile modifiée."
    end
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the star proposal
  def get_starproposal
    @starproposal = Starproposal.find_by_id(params[:id])
    return if check_nil_object(@starproposal)
    @submission = @starproposal.submission
    @problem = @submission.problem
  end
  
  # Get the submission
  def get_submission
    @submission = Submission.find_by_id(params[:submission_id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the submission is correct
  def correct_submission
    unless @submission.correct?
      flash[:danger] = "La soumission n'est pas correcte."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    end
  end
  
end

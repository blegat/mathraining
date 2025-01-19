#encoding: utf-8
class SavedrepliesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:new, :edit, :create, :update, :destroy]
  
  before_action :get_savedreply, only: [:edit, :update, :destroy]
  before_action :get_submission, only: [:new, :create, :edit, :update]
  
  # Create a saved reply (show the form)
  def new
    @savedreply = Savedreply.new(:problem => @submission.problem, :section => @submission.problem.section)
  end

  # Update a saved reply (show the form)
  def edit
  end
  
  # Create a saved reply (send the form)
  def create
    @savedreply = Savedreply.new(params.require(:savedreply).permit(:content))
    set_problem_or_section
    if @savedreply.save
      flash[:success] = "Réponse ajoutée."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    else
      render 'new'
    end
  end

  # Update a saved reply (send the form)
  def update
    @savedreply.content = params[:savedreply][:content]
    set_problem_or_section
    if @savedreply.save
      flash[:success] = "Réponse modifiée."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    else
      render 'edit'
    end
  end

  # Delete a saved reply
  def destroy
    @savedreply.destroy
    flash[:success] = "Réponse supprimée."
    redirect_back(fallback_location: root_path)
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the saved reply
  def get_savedreply
    @savedreply = Savedreply.find_by_id(params[:id])
    return if check_nil_object(@savedreply)
  end
  
  # Get the submission we come from (to redirect to it at the end)
  def get_submission
    @submission = Submission.find_by_id(params[:sub])
    return if check_nil_object(@submission)
  end
  
  ########## HELPER METHODS ##########
  
  def set_problem_or_section
    problem_id = params[:savedreply][:problem_id].to_i
    if problem_id > 0 # Saved reply specific to a problem
      problem = Problem.find_by_id(problem_id)
      unless problem_id.nil?
        @savedreply.problem = problem
        @savedreply.section_id = 0
      end
    elsif problem_id < 0 # Saved reply specific to a section
      @savedreply.problem_id = 0
      @savedreply.section_id = -problem_id
    else # Generic saved reply
      @savedreply.problem_id = 0
      @savedreply.section_id = 0
    end
  end
end

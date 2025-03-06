#encoding: utf-8
class SavedrepliesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:index, :show]
  before_action :corrector_user, only: [:new, :create]
  
  before_action :get_savedreply, only: [:show, :edit, :update, :destroy]
  before_action :get_submission, only: [:new, :create, :edit, :update]
  
  before_action :user_can_update_savedreply, only: [:edit, :update, :destroy]
  
  # Show non approved saved replies
  def index
  end
  
  # Show a submission where this saved reply can be seen
  def show
    redirect_to root_path if @savedreply.user_id != 0 # This method should not be used for personal saved replies
    if @savedreply.section_id == 0 && @savedreply.problem_id == 0
      submission = Submission.where.not(:status => [:closed, :plagiarized, :draft]).order(:created_at).last
    elsif @savedreply.section_id > 0
      submission = Submission.joins(:problem).where.not(:status => [:closed, :plagiarized, :draft]).where("problems.section_id = ?", @savedreply.section_id).order(:created_at).last
    else
      submission = Submission.where.not(:status => [:closed, :plagiarized, :draft]).where(:problem_id => @savedreply.problem_id).order(:created_at).last
    end
    redirect_to (submission.nil? ? root_path : problem_path(submission.problem, :sub => submission))
  end
  
  # Create a saved reply (show the form)
  def new
    @savedreply = Savedreply.new(:problem => @submission.problem, :section => @submission.problem.section, :user_id => 0)
  end

  # Update a saved reply (show the form)
  def edit
    if !@savedreply.approved
      @savedreply.content = @savedreply.content.split("\n").drop(2).join("\n")
    end
  end
  
  # Create a saved reply (send the form)
  def create
    @savedreply = Savedreply.new(params.require(:savedreply).permit(:content))
    set_problem_or_section_or_user
    @savedreply.approved = current_user.root? || @savedreply.user_id > 0
    if @savedreply.save
      if !@savedreply.approved
        @savedreply.update_attribute(:content, "(Proposé par #{current_user.name})\n\n" + @savedreply.content)
      end
      flash[:success] = "Réponse ajoutée."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    else
      render 'new'
    end
  end

  # Update a saved reply (send the form)
  def update
    @savedreply.content = params[:savedreply][:content]
    set_problem_or_section_or_user
    @savedreply.approved = current_user.root? || @savedreply.user_id > 0
    if @savedreply.save
      if !@savedreply.approved
        @savedreply.update_attribute(:content, "(Proposé par #{current_user.name})\n\n" + @savedreply.content)
      end
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
  
  ########## CHECK METHODS ##########
  
  # Check that current user can update this saved reply
  def user_can_update_savedreply
    unless current_user.root? || @savedreply.user == current_user
      render 'errors/access_refused'
    end
  end
  
  ########## HELPER METHODS ##########
  
  def set_problem_or_section_or_user
    @savedreply.problem_id = 0
    @savedreply.section_id = 0
    @savedreply.user_id = 0
    problem_id = params[:savedreply][:problem_id].to_i
    if problem_id > 0 # Saved reply specific to a problem
      problem = Problem.find_by_id(problem_id)
      unless problem_id.nil?
        @savedreply.problem = problem
      end
    elsif problem_id < -1 # Saved reply specific to a section
      @savedreply.section_id = -1-problem_id
    elsif problem_id == -1 # Generic personal saved reply
      @savedreply.user = current_user
    end
  end
end

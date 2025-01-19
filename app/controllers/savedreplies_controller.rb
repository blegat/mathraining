#encoding: utf-8
class SavedrepliesController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:index, :show, :edit, :update, :destroy]
  before_action :corrector_user, only: [:new, :create]
  
  before_action :get_savedreply, only: [:show, :edit, :update, :destroy]
  before_action :get_submission, only: [:new, :create, :edit, :update]
  
  # Show non approved saved replies
  def index
  end
  
  # Show a submission where this saved reply can be seen
  def show
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
    @savedreply = Savedreply.new(:problem => @submission.problem, :section => @submission.problem.section)
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
    set_problem_or_section
    @savedreply.approved = current_user.root? # Automatically approved for roots
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
    set_problem_or_section
    @savedreply.approved = true # Automatically approved for roots
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

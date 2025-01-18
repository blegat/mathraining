#encoding: utf-8
class SavedrepliesController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:new, :edit, :create, :update, :destroy]
  
  before_action :get_savedreply, only: [:edit, :update, :destroy]
  before_action :get_submission, only: [:new, :create, :edit, :update]
  
  # Create a saved reply (show the form)
  def new
    @savedreply = Savedreply.new(:problem => @submission.problem)
  end

  # Update a saved reply (show the form)
  def edit
  end
  
  # Create a saved reply (send the form)
  def create
    @savedreply = Savedreply.new(params.require(:savedreply).permit(:problem_id, :content))
    if @savedreply.save
      flash[:success] = "Réponse ajoutée."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    else
      render 'new'
    end
  end

  # Update a saved reply (send the form)
  def update
    if @savedreply.update(params.require(:savedreply).permit(:problem_id, :content))
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
end

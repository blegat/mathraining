#encoding: utf-8
class SuspicionsController < ApplicationController
  include SubmissionConcern
  before_action :signed_in_user, only: [:index]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :corrector_user, only: [:index, :create]
  before_action :root_user, only: [:update, :destroy]
  
  before_action :get_suspicion, only: [:update, :destroy]
  before_action :get_submission, only: [:create]
  
  before_action :user_can_correct_submission, only: [:create]

  # Show all suspicions (or only the ones that are not confirmed yet)
  def index
    if current_user.root?
      if params.has_key?:show_all
        # Show all suspicions
        @suspicions = Suspicion.joins(:submission).joins(submission: [{ problem: :section }]).select("suspicions.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).all.order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
      else
        # Show suspicions waiting for confirmation
        @suspicions = Suspicion.joins(:submission).joins(submission: [{ problem: :section }]).select("suspicions.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).where(:status => :waiting_confirmation).order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
      end
    else
      # Show all my suspicions
      @suspicions = current_user.suspicions.joins(:submission).joins(submission: [{ problem: :section }]).select("suspicions.*, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation").includes(:user, submission: :user).order("created_at DESC").paginate(:page => params[:page], :per_page => 50)
    end
  end
  
  # Delete a suspicion
  def destroy
    unless @suspicion.confirmed?
      @suspicion.destroy
      flash[:success] = "Suspicion supprimée."
      redirect_to problem_path(@submission.problem, :sub => @submission)
    end
  end
  
  # Create a suspicion
  def create
    suspicion = Suspicion.new(:user => current_user, :submission => @submission, :source => params[:suspicion][:source], :status => :waiting_confirmation)
    if suspicion.save
      flash[:success] = "Suspicion envoyée pour confirmation."
    else
      flash[:danger] = error_list_for(suspicion)
    end
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end
  
  # Update a suspicion (for example its status, to confirm it)
  def update
    old_status = @suspicion.status
    if @suspicion.update(params.require(:suspicion).permit(:user_id, :source, :status))
      if @submission.correct? && params[:suspicion][:status] == "confirmed"
        # Mark submission as incorrect (changing the user's score if needed)
        @submission.mark_incorrect
      elsif @submission.waiting? && @suspicion.status == "confirmed"
        # Delete the reservation, if any
        @submission.followings.where(:kind => :reservation).destroy_all
      end
      if old_status != "confirmed" && @suspicion.status == "confirmed" && !@submission.plagiarized?
        # Mark submission as plagiarized
        @submission.update(:status            => :plagiarized,
                           :last_comment_time => DateTime.now) # Because the new date for submission is 6 months after that date
        if @submission.intest? && @submission.score == -1
          @submission.update_attribute(:score, 0)
        end
        @submission.notified_users << @submission.user unless @submission.notified_users.exists?(@submission.user_id)
      elsif old_status == "confirmed" && @suspicion.status != "confirmed"
        # Mark submission as wrong or waiting instead of plagiarized (if no other suspicion is confirmed)
        if @submission.suspicions.where(:status => :confirmed).count == 0
          @submission.status = (@submission.corrections.where("user_id != ?", @submission.user).count == 0 ? :waiting : :wrong)
          last_comment = @submission.corrections.order(:id).last
          @submission.update_last_comment
          if @submission.waiting?
            # Delete the 'following' that was added automatically when submission was marked as plagiarized
            @submission.followings.destroy_all
          end
          @submission.notified_users << @submission.user unless @submission.notified_users.exists?(@submission.user_id)
        end
      end
      if @submission.plagiarized? && @submission.followings.count == 0
        Following.create(:user => @suspicion.user, :submission => @submission, :kind => :first_corrector, :read => true, :created_at => @suspicion.created_at)
      end
      flash[:success] = "Suspicion modifiée."
    end
    redirect_to problem_path(@submission.problem, :sub => @submission)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the suspicion
  def get_suspicion
    @suspicion = Suspicion.find_by_id(params[:id])
    return if check_nil_object(@suspicion)
    @submission = @suspicion.submission
    @problem = @submission.problem
  end
  
  # Get the submission
  def get_submission
    @submission = Submission.find_by_id(params[:submission_id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
end

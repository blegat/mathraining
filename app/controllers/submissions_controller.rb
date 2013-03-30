#encoding: utf-8
class SubmissionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :get_problem
  before_filter :online_chapter
  before_filter :unlocked_chapter
  before_filter :admin_user, only: [:correct]
  before_filter :not_solved, only: [:create]

  def show
    @submission = Submission.find_by_id(params[:id])
    if @submission.nil?
      redirect_to root_path
    end
  end

  def create
    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user
    if submission.save
      redirect_to problem_submission_path(@problem, submission)
    else
      flash_errors(submission)
    end
  end

  def correct
    @submission = Submission.find(params[:submission_id])
    if @submission
      @submission.status = 2
      @submission.save
      unless @submission.user.solved?(@problem)
        @problem.users << @submission.user
      end
      redirect_to problem_submission_path(@problem, @submission),
        flash: { success: 'Soumission marquée comme correcte' }
    else
      redirect_to root_path
    end
  end
  
  private

  def not_solved
    redirect_to root_path if current_user.solved?(@problem)
  end
  
  def get_problem
    @problem = Problem.find(params[:problem_id])
  end
  
  def online_chapter
    redirect_to sections_path unless (current_user.admin? || @problem.chapter.online)
  end
  
  def unlocked_chapter
    if !current_user.admin?
      @problem.chapter.prerequisites.each do |p|
        if (p.sections.count > 0 && !current_user.chapters.exists?(p))
          redirect_to sections_path and return
        end
      end
    end
  end

  def admin_user
    if not current_user.admin
      redirect_to root_path
    end
  end
  
end

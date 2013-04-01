#encoding: utf-8
class SubmissionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :get_problem
  before_filter :online_chapter
  before_filter :unlocked_chapter
  before_filter :admin_user, only: [:correct]
  before_filter :not_solved, only: [:create]
  before_filter :can_submit, only: [:create]

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
      redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id)
    else
      if params[:submission][:content].size == 0
        redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id),
          flash: { error: "Votre soumission est vide." }
      elsif params[:submission][:content].size > 8000
        redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id),
          flash: { error: "Votre soumission doit faire moins de 8000 caractères." }
      else
        redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id),
          flash: { error: "Une erreur est survenue." }
      end
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
  
  def can_submit
    lastsub = Submission.where(:user_id => current_user, :problem_id => @problem).order('created_at')
    redirect_to chapter_path(@problem.chapter, :type => 4, :which => @problem.id) if (!lastsub.empty? && lastsub.last.status == 0)
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

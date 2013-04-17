#encoding: utf-8
class SubmissionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :get_problem
  before_filter :online_chapter
  before_filter :unlocked_chapter
  before_filter :admin_user, only: [:read, :unread]
  before_filter :not_solved, only: [:create]
  before_filter :can_submit, only: [:create]
  before_filter :whatcolors

  def show
    # Marquer comme lu ??
    @submission = Submission.find_by_id(params[:id])
    if @submission.nil?
      redirect_to root_path
    end
    notif = current_user.notifs.where(submission_id: @submission.id)
    if notif.size > 0
      notif.first.delete
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

  def un_read(read, msg)
    @submission = Submission.find(params[:submission_id])
    if @submission
      following = Following.find_by_user_id_and_submission_id(current_user, @submission)
      if following
        following.read = read
        if following.save
          redirect_to problem_submission_path(@problem, @submission),
            flash: { success: "Soumission marquée comme #{msg}" }
        else
          redirect_to problem_submission_path(@problem, @submission),
            flash: { error: "Un problème est apparu" }
        end
      else
        redirect_to root_path
      end
    else
      redirect_to root_path
    end
  end

  def read
    un_read(true, "lue")
  end

  def unread
    un_read(false, "non lue")
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
  
  def point_attribution(user, problem)
    if !user.solved?(problem) # Avoid double count
      pt = 25*problem.level
      
      partials = user.pointspersections
    
      if !problem.chapter.sections.empty? # Pas un fondement
        user.point.rating = user.point.rating + pt
        user.point.save
      else # Fondement
        partial = partials.where(:section_id => 0).first
        partial.points = partial.points + pt
        partial.save
      end
    
      problem.chapter.sections.each do |s| # Section s
        partial = partials.where(:section_id => s.id).first
        partial.points = partial.points + pt
        partial.save
      end
    end
  end
end

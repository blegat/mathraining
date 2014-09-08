#encoding: utf-8
class SubmissionsController < ApplicationController
  before_filter :signed_in_user
  before_filter :get_problem
  before_filter :can_see, only: [:show]
  before_filter :admin_user, only: [:read, :unread]
  before_filter :not_solved, only: [:create]
  before_filter :can_submit, only: [:create]

  def show
    # Marquer comme lu ??
    if @submission.nil?
      redirect_to root_path
    end
    notif = current_user.sk.notifs.where(submission_id: @submission.id)
    if notif.size > 0 && !current_user.other
      notif.first.delete
    end

    @ancientexte = session[:ancientexte]
    session[:ancientexte] = nil
  end

  def create
  
    r = 0
    if(params.has_key?:r)
      r = params[:r].to_i
    end

    attach = Array.new
    totalsize = 0

    i = 1
    k = 1
    while !params["hidden#{k}".to_sym].nil? do
      if !params["file#{k}".to_sym].nil?
        attach.push()
        attach[i-1] = Submissionfile.new(:file => params["file#{k}".to_sym])
        if !attach[i-1].save
          j = 1
          while j < i do
            attach[j-1].file.destroy
            attach[j-1].destroy
            j = j+1
          end
          nom = params["file#{k}".to_sym].original_filename
          session[:ancientexte] = params[:submission][:content]
          redirect_to problem_path(@problem, :sub => 0, :r => r),
            flash: {danger: "Votre pièce jointe '#{nom}' ne respecte pas les conditions." } and return
        end
        totalsize = totalsize + attach[i-1].file_file_size

        i = i+1
      end
      k = k+1
    end

    if totalsize > 10485760
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      redirect_to problem_path(@problem, :sub => 0, :r => r),
          flash: {danger: "Vos pièces jointes font plus de 10 Mo au total (#{(totalsize.to_f/1048576.0).round(3)} Mo)" } and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk


    if submission.save
      j = 1
      while j < i do
        attach[j-1].submission = submission
        attach[j-1].save
        j = j+1
      end
      redirect_to problem_path(@problem, :sub => submission.id, :r => r)
    else
      j = 1
      while j < i do
        attach[j-1].file.destroy
        attach[j-1].destroy
        j = j+1
      end
      session[:ancientexte] = params[:submission][:content]
      if params[:submission][:content].size == 0
        flash[:danger] = "Votre soumission est vide."
        redirect_to problem_path(@problem, :sub => 0, :r => r)
      elsif params[:submission][:content].size > 8000
        flash[:danger] = "Votre soumission doit faire moins de 8000 caractères."
        redirect_to problem_path(@problem, :sub => 0, :r => r)
      else
        flash[:danger] = "Une erreur est survenue."
        redirect_to problem_path(@problem, :sub => 0, :r => r)
      end
    end
  end

  def un_read(read, msg)
    r = 0
    if(params.has_key?:r)
      r = params[:r].to_i
    end
    @submission = Submission.find(params[:submission_id])
    if @submission
      following = Following.find_by_user_id_and_submission_id(current_user.sk, @submission)
      if following
        following.read = read
        if following.save
          flash[:success] = "Soumission marquée comme #{msg}."
          redirect_to problem_path(@problem, :sub => @submission, :r => r)
        else
          flash[:danger] = "Un problème est apparu."
          redirect_to problem_path(@problem, :sub => @submission, :r => r)
        end
      elsif !read
        following = Following.new
        following.user = current_user.sk
        following.submission = @submission
        following.read = read
        if following.save
          flash[:success] = "Soumission marquée comme #{msg}."
          redirect_to problem_path(@problem, :sub => @submission, :r => r)
        else
          flash[:danger] = "Un problème est apparu."
          redirect_to problem_path(@problem, :sub => @submission, :r => r)
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

  def can_see
    @submission = Submission.find_by_id(params[:id])
    if ((@submission.problem != @problem) || (@submission.user != current_user.sk && !current_user.sk.solved?(@problem) && !current_user.sk.admin))
      redirect_to root_path
    end
  end

  def not_solved
    redirect_to root_path if current_user.sk.solved?(@problem)
  end

  def can_submit
    lastsub = Submission.where(:user_id => current_user.sk, :problem_id => @problem).order('created_at')
    redirect_to problem_path(@problem) if (!lastsub.empty? && lastsub.last.status == 0)
  end

  def get_problem
    @problem = Problem.find(params[:problem_id])
  end

  def admin_user
    if not current_user.sk.admin
      redirect_to root_path
    end
  end

  def point_attribution(user, problem)
    if !user.solved?(problem) # Avoid double count
      pt = problem.value

      partials = user.pointspersections

      if !problem.section.fondation? # Pas un fondement
        user.point.rating = user.point.rating + pt
        user.point.save
      end

      partial = partials.where(:section_id => problem.section.id).first
      partial.points = partial.points + pt
      partial.save
    end
  end
end

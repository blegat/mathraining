#encoding: utf-8
class SubmissionsController < ApplicationController
  before_action :signed_in_user, only: [:allsub, :allmysub, :allnewsub, :allmynewsub]
  before_action :signed_in_user_danger, only: [:create, :create_intest, :update_draft, :update_intest, :read, :unread, :star, :unstar, :reserve, :unreserve, :destroy, :update_score, :uncorrect, :search_script]
  before_action :non_admin_user, only: [:create, :create_intest, :update_draft, :update_intest]
  before_action :root_user, only: [:update_score]
  before_action :corrector_user, only: [:allsub, :allmysub, :allnewsub, :allmynewsub]
  
  before_action :get_submission, only: [:destroy]
  before_action :get_submission2, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :update_draft, :update_intest, :update_score, :uncorrect, :search_script]
  before_action :get_problem, only: [:create, :create_intest, :index]
  
  before_action :in_test_or_root_user, only: [:destroy]
  before_action :user_that_can_correct_submission, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :search_script, :uncorrect]
  before_action :online_problem, only: [:create, :create_intest]
  before_action :not_solved, only: [:create]
  before_action :can_submit, only: [:create]
  before_action :no_recent_plagiarism, only: [:create, :update_draft]
  before_action :user_that_can_see_problem, only: [:create]
  before_action :author, only: [:update_intest, :update_draft]
  before_action :in_test, only: [:create_intest, :update_intest]
  before_action :is_draft, only: [:update_draft]
  before_action :can_update_draft, only: [:update_draft]
  before_action :can_see_submissions, only: [:index]
  before_action :can_uncorrect_submission, only: [:uncorrect]

  # Show all submissions to a problem (only through js)
  def index
    if @what == 0
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where('user_id != ? AND status = ? AND star = ? AND visible = ?', current_user.sk, Submission.statuses[:correct], false, true).order('created_at DESC')
    elsif @what == 1
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where('user_id != ? AND status != ? AND status != ? AND visible = ?', current_user.sk, Submission.statuses[:correct], Submission.statuses[:waiting], true).order('created_at DESC')
    end

    respond_to do |format|
      format.js
    end
  end

  # Create a submission (send the form)
  def create
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    
    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      flash[:danger] = @error_message
      session[:ancientexte] = params[:submission][:content]
      redirect_to problem_path(@problem, :sub => 0) and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.last_comment_time = DateTime.now

    if params[:commit] == "Enregistrer comme brouillon"
      submission.visible = false
      submission.status = :draft
    end

    if submission.save
      attach_files(attach, submission)

      if submission.draft?
        flash[:success] = "Votre brouillon a bien été enregistré."
        redirect_to problem_path(@problem, :sub => 0)
      else
        flash[:success] = "Votre solution a bien été soumise."
        redirect_to problem_path(@problem, :sub => submission.id)
      end
    else
      destroy_files(attach)
      session[:ancientexte] = params[:submission][:content]
      flash[:danger] = error_list_for(submission)
      redirect_to problem_path(@problem, :sub => 0)
    end
  end

  # Create a submission during a test
  def create_intest
    oldsub = @problem.submissions.where(user_id: current_user.sk.id, intest: true).first
    if !oldsub.nil?
      @submission = oldsub
      @context = 1
      update_submission
      return
    end
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    
    # Attached files
    @error_message = ""
    attach = create_files
    if !@error_message.empty?
      flash[:danger] = @error_message
      session[:ancientexte] = params[:submission][:content]
      redirect_to virtualtest_path(@t, :p => @problem.id) and return
    end

    submission = @problem.submissions.build(content: params[:submission][:content])
    submission.user = current_user.sk
    submission.intest = true
    submission.visible = false
    submission.last_comment_time = DateTime.now

    if submission.save
      attach_files(attach, submission)
      flash[:success] = "Votre solution a bien été enregistrée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    else
      destroy_files(attach)
      session[:ancientexte] = params[:submission][:content]
      flash[:danger] = error_list_for(submission)
      redirect_to virtualtest_path(@t, :p => @problem.id)
    end
  end

  # Update a draft and maybe send it (send the form)
  def update_draft
    if params[:commit] == "Enregistrer le brouillon"
      @context = 2
      update_submission
    elsif params[:commit] == "Supprimer ce brouillon"
      @submission.destroy
      flash[:success] = "Brouillon supprimé."
      redirect_to @problem
    else
      @context = 3
      update_submission
    end
  end

  # Update a submission during a test
  def update_intest
    @context = 1
    update_submission
  end

  # Mark a submission as read
  def read
    un_read(true, "lue")
    if @submission.wrong_to_read?
      @submission.wrong!
    end
  end

  # Mark a submission as unread
  def unread
    un_read(false, "non lue")
  end

  # Give a star to a submission
  def star
    @submission.star = true if @submission.user != current_user.sk # Cannot star own solution
    @submission.save
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Remove the star of a submission
  def unstar
    @submission.star = false if @submission.user != current_user.sk # Cannot unstar own solution
    @submission.save
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Reserve a submission (only through js)
  def reserve
    if @submission.followings.count > 0 && @submission.followings.first.user != current_user.sk # Already reserved by somebody else
      f = @submission.followings.first
      @correct_name = f.user.name
      @reservation_date = f.created_at
      @what = 2
    else
      if @submission.followings.count == 0 # Avoid adding two times the same Following
        f = Following.create(:user       => current_user.sk,
                             :submission => @submission,
                             :read       => true,
                             :kind       => 0)
      end
      @what = 3
    end
    
    respond_to do |format|
      format.js
    end
  end

  # Unreserve a submission (only through js)
  def unreserve
    f = @submission.followings.first
    if !@submission.waiting? || f.nil? || (f.user != current_user.sk && !current_user.sk.root?) || f.kind != 0 # Not supposed to happen
      @what = 0
    else
      Following.delete(f.id)
      @what = 1
    end
  end

  # Delete a submission
  def destroy
    @submission.destroy
    if current_user.sk.admin?
      flash[:success] = "Soumission supprimée."
      redirect_to problem_path(@problem)
    else
      # Student in a test
      flash[:success] = "Solution supprimée."
      redirect_to virtualtest_path(@t, :p => @problem.id)
    end
  end
  
  # Update the score of a submission in a test
  def update_score
    if @submission.intest && @submission.score != -1
      @submission.score = params[:new_score].to_i
      @submission.save
    end
    redirect_to problem_path(@problem, :sub => @submission)
  end
  
  # Mark a correct solution as incorrect (only in case of mistake)
  def uncorrect
    @submission.mark_incorrect
    flash[:success] = "Soumission marquée comme erronée."
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Search for some strings in all submissions to the problem (only through js)
  def search_script
    @string_to_search = params[:string_to_search]
    @enough_caracters = (@string_to_search.size >= 3)

    if @enough_caracters
      search_in_comments = !params[:search_in_comments].nil?

      @all_found = Array.new

      @problem.submissions.where(:visible => true).order("created_at DESC").each do |s|
        pos = s.content.index(@string_to_search)
        if !pos.nil?
          @all_found.push([s, strip_content(s.content, @string_to_search, pos)])
        elsif search_in_comments
          s.corrections.where(:user => s.user).each do |c|
            pos = c.content.index(@string_to_search)
            if !pos.nil?
              @all_found.push([s, strip_content(c.content, @string_to_search, pos)])
            end
          end
        end
      end
    end

    respond_to do |format|
      format.js
    end
  end
  
  # Show all submissions
  def allsub
    @submissions = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user, followings: :user).where(:visible => true).order("submissions.last_comment_time DESC").paginate(page: params[:page]).to_a
  end

  # Show all submissions in which we took part
  def allmysub
    @submissions = current_user.sk.followed_submissions.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user).where("status != ? AND status != ?", Submission.statuses[:draft], Submission.statuses[:waiting]).order("submissions.last_comment_time DESC").paginate(page: params[:page]).to_a
  end
  
  # Show all new submissions
  def allnewsub
    levels = [1, 2, 3, 4, 5]
    if (params.has_key?:levels)
      levels = []
      levels_int = params[:levels].to_i
      for l in [1, 2, 3, 4, 5]
        if (levels_int & (1 << (l-1)) != 0)
          levels.push(l)
        end
      end
    end
    section_condition = ((params.has_key?:section) and params[:section].to_i > 0) ? "problems.section_id = #{params[:section].to_i}" : ""
    @submissions = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions(true)).includes(:user, followings: :user).where(:status => :waiting, :visible => true).where(section_condition).where("problems.level in (?)", levels).order("submissions.created_at").to_a
  end

  # Show all new comments to submissions in which we took part
  def allmynewsub
    @submissions = current_user.sk.followed_submissions.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user).where(followings: {read: false}).order("submissions.last_comment_time").to_a
    @submissions_other = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user, followings: :user).where(:status => :wrong_to_read).order("submissions.last_comment_time").to_a
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the submission
  def get_submission
    @submission = Submission.find_by_id(params[:id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
  # Get the submission (v2)
  def get_submission2
    @submission = Submission.find_by_id(params[:submission_id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
  # Get the problem (if possible)
  def get_problem
    @problem = Problem.find_by_id(params[:problem_id])
    return if check_nil_object(@problem)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the problem is online
  def online_problem
    return if check_offline_object(@problem)
  end

  # Check that current user did not already solve the problem
  def not_solved
    redirect_to root_path if current_user.sk.pb_solved?(@problem)
  end

  # Check that current user can create a new submission for the problem
  def can_submit
    redirect_to problem_path(@problem) and return if @no_new_submission
    if current_user.sk.submissions.where(:problem => @problem, :status => [:draft, :waiting]).count > 0
      redirect_to problem_path(@problem) and return
    end
  end
  
  # Check that current user can update his draft to a problem
  def can_update_draft
    redirect_to problem_path(@problem) if @no_new_submission
  end
  
  # Check that current user has no (recent) plagiarized solution to the problem
  def no_recent_plagiarism
    s = current_user.sk.submissions.where(:problem => @problem, :status => :plagiarized).order(:last_comment_time).last
    if !s.nil? && s.last_comment_time.to_date + 6.months > Date.today
      redirect_to problem_path(@problem) and return
    end
  end

  # Check that current user is doing a test with this problem
  def in_test
    @t = @problem.virtualtest
    return if check_nil_object(@t)
    redirect_to virtualtests_path if current_user.sk.test_status(@t) != "in_progress"
  end
  
  # Check that current user is doing a test with this problem, or is a root
  def in_test_or_root_user
    if !current_user.sk.root?
      in_test
    end
  end
  
  # Check that current user is the author of the submission
  def author
    if @submission.user != current_user.sk
      render 'errors/access_refused' and return
    end
  end

  # Check that the submission is a draft
  def is_draft
    unless @submission.draft?
      redirect_to @problem
    end
  end
  
  # Check that current user can see the correct/incorrect submissions to the problem
  def can_see_submissions
    redirect_to root_path if !(params.has_key?:what)
    @what = params[:what].to_i
    redirect_to root_path if (@what != 0 and @what != 1)
    if @what == 0    # See correct submissions (need to have solved problem or to be admin)
      redirect_to root_path if !current_user.sk.admin? and !current_user.sk.pb_solved?(@problem)
    else # (@what == 1) # See incorrect submissions (need to be admin or corrector)
      redirect_to root_path if !current_user.sk.admin? and !current_user.sk.corrector?
    end
  end
  
  # Check that current user can uncorrect the current submission
  def can_uncorrect_submission
    # Submission must be correct to be marked as wrong
    redirect_to problem_path(@problem, :sub => @submission) unless @submission.correct?
    unless current_user.sk.root?
      # Corrector should have accepted the solution a few minutes ago
      eleven_minutes_ago = DateTime.now - 11.minutes
      if Solvedproblem.where(:user => @submission.user, :problem => @problem).first.correction_time < eleven_minutes_ago or @submission.corrections.where(:user => current_user.sk).where("created_at > ?", eleven_minutes_ago).count == 0
        flash[:danger] = "Vous ne pouvez plus marquer cette solution comme erronée."
        redirect_to problem_path(@problem, :sub => @submission)
      end
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to update the submission
  def update_submission
    if @context == 1
      lepath = virtualtest_path(@t, :p => @problem.id) # Update in test
    elsif @context == 2
      lepath = problem_path(@problem, :sub => 0) # Update a draft
    else
      lepath = problem_path(@problem, :sub => 0) # Update and send a draft
    end
    
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    @submission.content = params[:submission][:content]
    if @submission.valid?

      # Attached files
      @error_message = ""
      update_files(@submission)
      if !@error_message.empty?
        flash[:danger] = @error_message
        session[:ancientexte] = params[:submission][:content]
        redirect_to lepath and return
      end
      
      @submission.save

      if @context == 1
        flash[:success] = "Votre solution a bien été modifiée."
        redirect_to virtualtest_path(@t, :p => @problem.id)
      elsif @context == 2
        flash[:success] = "Votre brouillon a bien été enregistré."
        redirect_to lepath
      else
        @submission.status = :waiting
        @submission.created_at = DateTime.now
        @submission.last_comment_time = @submission.created_at
        @submission.visible = true
        @submission.save
        flash[:success] = "Votre solution a bien été soumise."
        redirect_to problem_path(@problem, :sub => @submission.id)
      end
    else
      session[:ancientexte] = params[:submission][:content]
      flash[:danger] = error_list_for(@submission)
      redirect_to lepath
    end
  end

  # Helper method to mark as read/unread
  def un_read(read, msg)
    following = Following.where(:user_id => current_user.sk, :submission_id => @submission).first
    if !following.nil?
      following.update_attribute(:read, read)
      flash[:success] = "Soumission marquée comme #{msg}."
    end
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Helper method to create a preview of a substring of a string
  def strip_content(content, string_found, pos)
    start1 = [pos - 30, 0].max
    if start1 < 4
      start1 = 0
    end
    stop1 = pos
    start2 = pos + string_found.size
    stop2 = [start2 + 30, content.size].min
    if stop2 > content.size - 4
      stop2 = content.size
    end
    return [(start1 > 0 ? "..." : "") + content[start1, stop1-start1], content[start2, stop2-start2] + (stop2 < content.size ? "..." : "")]
  end
  
  # Helper method to list columns that are needed to list submissions
  def needed_columns_for_submissions(include_content_length = false)
    columns = "submissions.id, submissions.user_id, submissions.problem_id, submissions.status, submissions.star, submissions.created_at, submissions.last_comment_time, submissions.intest, problems.level AS problem_level, sections.short_abbreviation AS section_short_abbreviation"
    if include_content_length
      columns += ", length(submissions.content) AS content_length"
    end
    return columns
  end
end

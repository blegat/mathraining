#encoding: utf-8
class SubmissionsController < ApplicationController
  include ProblemConcern
  include SubmissionConcern
  include FileConcern
  
  skip_before_action :error_if_invalid_csrf_token, only: [:create, :update] # Do not forget to check @invalid_csrf_token instead!

  before_action :signed_in_user, only: [:show, :new, :all, :allmy, :allnew, :allmynew, :allhidden, :next_good, :prev_good]
  before_action :signed_in_user_danger, only: [:create, :update, :read, :unread, :star, :unstar, :reserve, :unreserve, :destroy, :update_score, :mark_wrong, :mark_correct, :search_script]
  before_action :non_admin_user, only: [:create]
  before_action :root_user, only: [:allhidden, :update_score, :star, :unstar, :next_good, :prev_good]
  before_action :corrector_user, only: [:all, :allmy, :allnew, :allmynew]
  
  before_action :get_submission, only: [:show, :update, :destroy, :send_draft, :read, :unread, :reserve, :unreserve, :star, :unstar, :update_score, :mark_wrong, :mark_correct, :search_script, :next_good, :prev_good]
  before_action :get_problem, only: [:show, :new, :index, :create]
  before_action :get_virtualtest_if_any, only: [:create, :update, :destroy]
  
  before_action :submission_of_problem, only: [:show]
  before_action :user_can_see_problem, only: [:show, :new]
  before_action :user_can_see_submission, only: [:show]
  before_action :user_can_see_problem_or_in_test, only: [:create]
  before_action :user_did_not_solve_problem, only: [:create]
  before_action :user_can_write_submission_to_problem, only: [:create, :send_draft]
  before_action :author_of_submission_or_root, only: [:update, :destroy]
  before_action :author_of_submission, only: [:send_draft]
  before_action :draft_submission_or_root, only: [:update, :destroy]
  before_action :draft_submission, only: [:send_draft]
  before_action :new_submissions_allowed_or_in_test, only: [:create, :update, :send_draft]
  before_action :user_has_no_recent_cheating_or_closure, only: [:create, :update, :send_draft]
  before_action :user_can_write_submission_or_in_test, only: [:create, :send_draft]
  before_action :user_can_send_today, only: [:send_draft]
  before_action :user_not_in_test, only: [:send_draft]
  before_action :user_can_see_submissions, only: [:index]
  before_action :user_can_correct_submission, only: [:read, :unread, :reserve, :unreserve, :search_script, :mark_wrong, :mark_correct]
  before_action :user_can_mark_submission_as_wrong, only: [:mark_wrong]
  before_action :user_can_mark_submission_as_correct, only: [:mark_correct]
  
  before_action :show_flash_info_if_no_new_submission, only: [:show, :new]

  # Show all submissions to a problem (only through js)
  def index
    if @what == 0
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where.not(:user => current_user).where(:status => :correct, :star => false).order('created_at DESC')
    elsif @what == 1
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where.not(:user => current_user).where(:status => [:wrong, :wrong_to_read, :plagiarized, :closed]).order('created_at DESC')
    end

    respond_to :js
  end
  
  # Show one submission
  def show
    @correction = Correction.new unless @submission.draft?
  end
  
  # Create a submission (show the form, not in a test)
  def new
    @submission = @problem.submissions.where(:user => current_user, :status => :draft).first # In case there is a draft
    @submission = Submission.new if @submission.nil? # In case there is no draft
  end
  
  # Create a submission (during a test or not)
  def create
    oldsub = @problem.submissions.where(user_id: current_user.id, status: :draft).first
    if !oldsub.nil?
      @submission = oldsub
      update and return
    end
    
    intest = !@virtualtest.nil?
    if intest
      rendered_page_in_case_of_error = 'virtualtests/show'
    else
      rendered_page_in_case_of_error = 'submissions/new'
    end
    params[:submission][:content].strip! if !params[:submission][:content].nil?

    @submission = @problem.submissions.build(:content => params[:submission][:content],
                                             :user    => current_user,
                                             :intest  => intest,
                                             :status  => :draft)
    
    # Save submission, handling usual errors
    if !save_object_handling_errors(@submission, rendered_page_in_case_of_error)
      return
    end
    
    flash[:success] = "Votre solution a bien été enregistrée."
    if intest
      redirect_to virtualtest_path(@virtualtest, :p => @problem.id)
    else
      redirect_to new_problem_submission_path(@problem)
    end
  end
  
  # Update a draft submission (in test or not), or any submission for a root
  def update
    intest = !@virtualtest.nil?
    if current_user.root?
      @correction = Correction.new unless @submission.draft?
      rendered_page_in_case_of_error = 'submissions/show'
    elsif intest
      rendered_page_in_case_of_error = 'virtualtests/show'
    else
      rendered_page_in_case_of_error = 'submissions/new'
    end
    
    params[:submission][:content].strip! if !params[:submission][:content].nil?
    @submission.content = params[:submission][:content]
    
    # Save submission, handling usual errors
    if !save_object_handling_errors(@submission, rendered_page_in_case_of_error)
      return
    end

    if current_user.root?
      flash[:success] = "Solution modifiée."
      redirect_to problem_submission_path(@problem, @submission)
    elsif intest
      flash[:success] = "Votre solution a bien été enregistrée."
      redirect_to virtualtest_path(@virtualtest, :p => @problem.id)
    else
      update_draft_dates
      flash[:success] = "Votre solution a bien été enregistrée."
      redirect_to new_problem_submission_path(@problem)
    end
  end
  
  # Delete a draft submission (in a test or not) or any (wrong) submission for a root
  def destroy
    intest = @submission.intest?
    @submission.destroy
    if current_user.root?
      flash[:success] = "Solution supprimée."
      redirect_to problem_path(@problem)
    elsif intest
      flash[:success] = "Votre solution a bien été supprimée."
      redirect_to virtualtest_path(@virtualtest, :p => @problem.id)
    else
      flash[:success] = "Votre solution a bien été supprimée."
      redirect_to problem_path(@problem)
    end
  end
  
  # Send a draft for correction (not in a test)
  def send_draft
    update_draft_dates
    @submission.set_waiting_status
    flash[:success] = "Votre solution a bien été soumise pour être corrigée."
    redirect_to problem_submission_path(@problem, @submission)
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
    @submission.update_attribute(:star, true)
    redirect_to problem_submission_path(@problem, @submission)
  end

  # Remove the star of a submission
  def unstar
    @submission.update_attribute(:star, false)
    redirect_to problem_submission_path(@problem, @submission)
  end

  # Reserve a submission (only through js)
  def reserve
    if @submission.followings.count > 0 && @submission.followings.first.user != current_user # Already reserved by somebody else
      f = @submission.followings.first
      @correct_name = f.user.name
      @reservation_date = f.created_at
      @what = 2
    else
      if @submission.followings.count == 0 # Avoid adding two times the same Following
        f = Following.create(:user       => current_user,
                             :submission => @submission,
                             :read       => true,
                             :kind       => :reservation)
      end
      @what = 3
    end
    respond_to :js
  end

  # Unreserve a submission (only through js)
  def unreserve
    f = @submission.followings.first
    if !@submission.waiting? || f.nil? || (f.user != current_user && !current_user.root?) || !f.reservation? # Not supposed to happen
      @what = 0
    else
      Following.delete(f.id)
      @what = 1
    end
    respond_to :js
  end
  
  # Update the score of a submission in a test
  def update_score
    if @submission.intest && @submission.score != -1
      @submission.update(:score => params[:new_score].to_i) # Do not use update_attribute because it does not trigger validations
    end
    redirect_to problem_submission_path(@problem, @submission)
  end
  
  # Mark a correct solution as incorrect (only in case of mistake)
  def mark_wrong
    @submission.mark_incorrect
    flash[:success] = "Soumission marquée comme erronée."
    redirect_to problem_submission_path(@problem, @submission)
  end
  
  # Mark a wrong submission as correct without a commmment (only in case of mistake)
  def mark_correct
    @submission.mark_correct
    flash[:success] = "Soumission marquée comme correcte."
    redirect_to problem_submission_path(@problem, @submission)
  end

  # Search for some strings in all submissions to the problem (only through js)
  def search_script
    @string_to_search = Extract.get_cleaned_string(params[:string_to_search]) # Need to clean before checking number of characters
    @enough_caracters = (@string_to_search.size >= 3)

    if @enough_caracters
      search_in_comments = !params[:search_in_comments].nil?

      @all_found = Array.new

      @problem.submissions.where.not(:status => :draft).order("created_at DESC").each do |s|
        res = Extract.find_if_included_in(s.content, @string_to_search)
        if !res.nil?
          @all_found.push([s, strip_content(s.content, res)])
        elsif search_in_comments
          s.corrections.where(:user => s.user).each do |c|
            res = Extract.find_if_included_in(c.content, @string_to_search)
            if !res.nil?
              @all_found.push([s, strip_content(c.content, res)])
            end
          end
        end
      end
    end
    respond_to :js
  end
  
  # Show all submissions
  def all
    @submissions = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user, followings: :user).where.not(:status => :draft).order("submissions.last_comment_time DESC").paginate(page: params[:page]).to_a
  end

  # Show all submissions in which we took part
  def allmy
    @submissions = current_user.followed_submissions.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user).where.not(:status => [:draft, :waiting]).order("submissions.last_comment_time DESC").paginate(page: params[:page]).to_a
  end
  
  # Show all new submissions
  def allnew
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
    section_condition = ((params.has_key?:section) && params[:section].to_i > 0) ? "problems.section_id = #{params[:section].to_i}" : ""
    favorite_condition = ((params.has_key?:fav) && params[:fav].to_i == 1) ? "problems.id IN (SELECT favoriteproblems.problem_id FROM favoriteproblems WHERE favoriteproblems.user_id = #{current_user.id})" : ""
    @submissions = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions(true)).includes(:user, followings: :user).where(:status => :waiting).where(section_condition).where("problems.level in (?)", levels).where(favorite_condition).order("submissions.created_at").to_a
  end

  # Show all new comments to submissions in which we took part
  def allmynew
    @submissions = current_user.followed_submissions.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user).where(followings: {read: false}).order("submissions.last_comment_time").to_a
    @submissions_other = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user, followings: :user).where(:status => :wrong_to_read).order("submissions.last_comment_time").to_a
  end
  
  # Show all waiting submissions that will not be corrected
  def allhidden
    @submissions = Submission.joins(:problem).joins(problem: :section).select(needed_columns_for_submissions).includes(:user, followings: :user).where(:status => :waiting_forever).order("submissions.created_at").to_a
  end
  
  # Go to the next good submission (when searching for submissions to star)
  def next_good
    submission = @problem.submissions.joins("INNER JOIN solvedproblems ON solvedproblems.submission_id = submissions.id").where("created_at > ? AND submissions.created_at = solvedproblems.resolution_time", @submission.created_at).order(:created_at).first
    if submission.nil?
      submission = @submission
      flash[:info] = "Aucune soumission trouvée."
    end
    redirect_to problem_submission_path(@problem, submission)
  end
  
  # Go to the previous good submission (when searching for submissions to star)
  def prev_good
    submission = @problem.submissions.joins("INNER JOIN solvedproblems ON solvedproblems.submission_id = submissions.id").where("created_at < ? AND submissions.created_at = solvedproblems.resolution_time", @submission.created_at).order("created_at DESC").first
    if submission.nil?
      submission = @submission
      flash[:info] = "Aucune soumission trouvée."
    end
    redirect_to problem_submission_path(@problem, submission)
  end

  private
  
  ########## GET METHODS ##########
  
  # Get the submission
  def get_submission
    @submission = Submission.find_by_id(params[:id])
    return if check_nil_object(@submission)
    @problem = @submission.problem
  end
  
  # Get the problem (if possible)
  def get_problem
    @problem = Problem.find_by_id(params[:problem_id])
    return if check_nil_object(@problem)
  end
  
  # Get the virtualtest, if user is currently doing a virtualtest
  def get_virtualtest_if_any
    return if current_user.admin?
    virtualtest = @problem.virtualtest
    return if virtualtest.nil?
    if current_user.test_status(virtualtest) == "in_progress"
      @virtualtest = virtualtest
    end
    if !@submission.nil? && @submission.intest? && @virtualtest.nil? # Try to update or destroy a submission in test, but too late
      redirect_to virtualtests_path
    end
  end
  
  ########## CHECK METHODS ##########
  
  # Check that submission belongs to problem
  def submission_of_problem
    if @submission.problem != @problem
      render 'errors/access_refused'
    end
  end
  
  # Check that current user can see this submission
  def user_can_see_submission
    if !@submission.can_be_seen_by(current_user)
      redirect_to problem_path(@problem)
    end
  end
  
  # Check that current user can see the problem or is in a virtualtest
  def user_can_see_problem_or_in_test
    if @virtualtest.nil?
      user_can_see_problem # Defined in problem_concern.rb
    end
  end

  # Check that current user did not already solve the problem
  def user_did_not_solve_problem
    redirect_to problem_path(@problem) if current_user.pb_solved?(@problem)
  end
  
  # Check that new submissions are allowed, or that the user is in a virtualtest
  def new_submissions_allowed_or_in_test
    if @virtualtest.nil?
      redirect_to problem_path(@problem) if @no_new_submission
    end
  end

  # Check that current user can create a new submission for the problem
  def user_can_write_submission_to_problem
    if current_user.submissions.where(:problem => @problem, :status => [:waiting, :waiting_forever]).count > 0
      redirect_to problem_path(@problem)
    end
  end
  
  # Check that current user can write a submission, or is in a virtualtest
  def user_can_write_submission_or_in_test
    if @virtualtest.nil?
      user_can_write_submission # Defined in application_controller.rb
    end
  end
  
  # Check that the submission is a draft
  def draft_submission
    if !@submission.draft?
      flash[:danger] = "Vous ne pouvez plus modifier cette solution."
      redirect_to problem_submission_path(@problem, @submission)
    end
  end
  
  # Check that the submission is a draft, or current user is a root
  def draft_submission_or_root
    if !current_user.root?
      draft_submission
    end
  end
  
  # Check that current user is the author of the submission
  def author_of_submission
    if @submission.user != current_user
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is the author of the submission, or a root
  def author_of_submission_or_root
    if !current_user.root?
      author_of_submission
    end
  end
  
  # Check that current user can send a new submission today
  def user_can_send_today
    if @limited_new_submissions && current_user.has_already_submitted_today?
      redirect_to new_problem_submission_path(@problem)
    end
  end
  
  # Check that current user is not in a test (for this submission)
  def user_not_in_test
    render 'errors/access_refused' if !@virtualtest.nil?
  end
  
  # Check that current user can see the correct/incorrect submissions to the problem
  def user_can_see_submissions
    redirect_to root_path if !(params.has_key?:what)
    @what = params[:what].to_i
    redirect_to root_path if (@what != 0 && @what != 1)
    if @what == 0    # See correct submissions (need to have solved problem or to be admin)
      redirect_to root_path if !current_user.admin? && !current_user.pb_solved?(@problem)
    else # (@what == 1) # See incorrect submissions (need to be admin or corrector)
      redirect_to root_path if !current_user.admin? && !current_user.corrector?
    end
  end
  
  # Check that current user can mark the current submission as wrong
  def user_can_mark_submission_as_wrong
    # Submission must be correct to be marked as wrong
    redirect_to problem_submission_path(@problem, @submission) unless @submission.correct?
    return if current_user.root? # Root can always mark as wrong
    return if current_user.correction_level >= 12 && @submission.last_comment_time > DateTime.now - 7.days - 1.hour # Experienced corrector can mark as wrong during one week
    # Corrector should have accepted the solution a few minutes ago
    eleven_minutes_ago = DateTime.now - 11.minutes
    if Solvedproblem.where(:user => @submission.user, :problem => @problem).first.correction_time < eleven_minutes_ago || @submission.corrections.where(:user => current_user).where("created_at > ?", eleven_minutes_ago).count == 0
      flash[:danger] = "Vous ne pouvez plus marquer cette solution comme erronée."
      redirect_to problem_submission_path(@problem, @submission)
    end
  end
  
  # Check that current user can mark the current submission as correct (without a comment)
  def user_can_mark_submission_as_correct
    # Submission must be wrong to be marked as correct
    redirect_to problem_submission_path(@problem, @submission) unless @submission.wrong?
    # Corrector should have rejected the solution a few minutes ago
    eleven_minutes_ago = DateTime.now - 11.minutes
    if @submission.corrections.where(:user => current_user).where("created_at > ?", eleven_minutes_ago).count == 0
      flash[:danger] = "Vous ne pouvez plus marquer cette solution comme correcte sans laisser un commentaire."
      redirect_to problem_submission_path(@problem, @submission)
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Helper method to update the dates of a draft submission when updating or sending it
  def update_draft_dates
    date_now = DateTime.now
    @submission.update(:created_at => date_now, :last_comment_time => date_now)
  end

  # Helper method to mark as read/unread
  def un_read(read, msg)
    following = Following.where(:user_id => current_user, :submission_id => @submission).first
    if !following.nil?
      following.update_attribute(:read, read)
      flash[:success] = "Soumission marquée comme #{msg}."
    end
    redirect_to problem_submission_path(@problem, @submission)
  end

  # Helper method to create a preview of a substring of a string
  def strip_content(content, res)
    start2 = res[0]
    stop2 = res[1]
    start1 = [start2 - 30, 0].max
    if start1 <= 3
      start1 = 0
    end
    stop1 = start2
    start3 = stop2
    stop3 = [start3 + 30, content.size].min
    if stop3 >= content.size - 3
      stop3 = content.size
    end
    return [(start1 > 0 ? "..." : "") + content[start1, stop1-start1], content[start2, stop2-start2], content[start3, stop3-start3] + (stop3 < content.size ? "..." : "")]
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

#encoding: utf-8
class SubmissionsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :create_intest, :update_draft, :update_intest, :read, :unread, :star, :unstar, :reserve, :unreserve, :destroy, :update_score, :uncorrect, :mark_as_plagiarism, :search_script]
  before_action :non_admin_user, only: [:create, :create_intest, :update_draft, :update_intest]
  before_action :root_user, only: [:update_score, :uncorrect, :mark_as_plagiarism]
  
  before_action :get_submission, only: [:destroy]
  before_action :get_submission2, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :update_draft, :update_intest, :update_score, :uncorrect, :mark_as_plagiarism, :search_script]
  before_action :get_problem, only: [:create, :create_intest, :index]
  
  before_action :in_test_or_root_user, only: [:destroy]
  before_action :corrector_user_having_access, only: [:read, :unread, :reserve, :unreserve, :star, :unstar, :search_script]
  before_action :online_problem, only: [:create, :create_intest]
  before_action :not_solved, only: [:create]
  before_action :can_submit, only: [:create]
  before_action :no_recent_plagiarism, only: [:create, :update_draft]
  before_action :user_that_can_see_problem, only: [:create]
  before_action :author, only: [:update_intest, :update_draft]
  before_action :in_test, only: [:create_intest, :update_intest]
  before_action :is_draft, only: [:update_draft]
  before_action :can_see_submissions, only: [:index]

  # Show all submissions to a problem (only through js)
  def index
    if @what == 0
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where('user_id != ? AND status = 2 AND star = ? AND visible = ?', current_user.sk, false, true).order('created_at DESC')
    elsif @what == 1
      @submissions = @problem.submissions.select(:id, :status, :star, :user_id, :problem_id, :intest, :created_at, :last_comment_time).includes(:user).where('user_id != ? AND status != 2 AND status != 0 AND visible = ?', current_user.sk, true).order('created_at DESC')
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
      submission.status = -1
    end

    if submission.save
      attach_files(attach, submission)

      if submission.status == -1
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
    if @submission.status == 3
      @submission.status = 1
      @submission.save
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
    if @submission.status != 0 || f.nil? || (f.user != current_user.sk && !current_user.sk.root?) || f.kind != 0 # Not supposed to happen
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
    u = @submission.user
    if @submission.status == 2
      @submission.status = 1
      @submission.star = false
      @submission.save
      nb_corr = Submission.where(:problem => @problem, :user => u, :status => 2).count
      if nb_corr == 0
        # Si c'était la seule soumission correcte, alors il faut agir et baisser le score
        sp = Solvedproblem.where(:submission => @submission).first
        sp.destroy
        u.rating = u.rating - @problem.value
        u.save
        pps = Pointspersection.where(:user => u, :section_id => @problem.section).first
        pps.points = pps.points - @problem.value
        pps.save
      else
        # Si il y a d'autres soumissions il faut peut-être modifier le submission_id du Solvedproblem correspondant
        sp = Solvedproblem.where(:problem => @problem, :user => u).first
        if sp.submission == @submission
          which = -1
          correction_time = nil
          resolution_time = nil
          Submission.where(:problem => @problem, :user => u, :status => 2).each do |s| 
            lastcomm = s.corrections.where("user_id != ?", u.id).order(:created_at).last
            if(which == -1 || lastcomm.created_at < correction_time)
              which = s.id
              correction_time = lastcomm.created_at
              usercomm = s.corrections.where("user_id = ? AND created_at < ?", u.id, correction_time).last
              resolution_time = (usercomm.nil? ? s.created_at : usercomm.created_at)
            end
          end
          sp.submission_id = which
          sp.correction_time = correction_time
          sp.resolution_time = resolution_time
          sp.save
        end
      end
    end
    redirect_to problem_path(@problem, :sub => @submission)
  end

  # Mark a submission as plagiarized
  def mark_as_plagiarism
    @submission.status = 4
    @submission.save
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
    if current_user.sk.submissions.where(:problem => @problem, :status => [-1, 0]).count > 0 # Draft or waiting
      redirect_to problem_path(@problem) and return
    end
  end
  
  # Check that current user has no (recent) plagiarized solution to the problem
  def no_recent_plagiarism
    s = current_user.sk.submissions.where(:problem => @problem, :status => 4).order(:last_comment_time).last
    if !s.nil? && s.last_comment_time.to_date + 6.months > Date.today
      redirect_to problem_path(@problem) and return
    end
  end

  # Check that current user is doing a test with this problem
  def in_test
    @t = @problem.virtualtest
    return if check_nil_object(@t)
    redirect_to virtualtests_path if current_user.sk.status(@t) != 0
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
    unless @submission.status == -1
      redirect_to @problem
    end
  end

  # Check that current user is a corrector (or admin) having access to the problem
  def corrector_user_having_access
    unless current_user.sk.admin or (current_user.sk.corrector && current_user.sk.pb_solved?(@problem) && current_user.sk != @submission.user)
      render 'errors/access_refused' and return
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
        @submission.status = 0
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
end

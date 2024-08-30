#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_action :load_global_variables
  before_action :check_under_maintenance
  before_action :has_consent
  before_action :check_takentests

  private

  # When doing big changes on the server
  def check_under_maintenance
    if @under_maintenance
      flash[:info] = @under_maintenance_message.html_safe
      if !@signed_in || !current_user.root?
        redirect_to root_path if request.path != "/"
      end
    end
  end
  
  # Create some global variables that are always needed
  def load_global_variables
    @signed_in = signed_in?
    
    if params.has_key?(:start_benchmark)
      cookies[:benchmark] = 1
    end
    if cookies.has_key?(:benchmark)
      if params.has_key?(:stop_benchmark)
        cookies.delete(:benchmark)
      else
        @benchmark_start_time = Time.now
      end
    end
    
    @under_maintenance = false
    @no_new_submission = false
    @limited_new_submissions = false
    Globalvariable.all.each do |g|
      if g.key == "under_maintenance"
        @under_maintenance = g.value
        @under_maintenance_message = g.message
      elsif g.key == "no_new_submission"
        @no_new_submission = g.value
        @no_new_submission_message = g.message
      elsif g.key == "limited_new_submissions"
        @limited_new_submissions = g.value
      end
    end
  end
  
  # Check that the user consented to the last policy
  def has_consent
    pp = request.fullpath.to_s
    if @signed_in && !current_user.last_policy_read && pp != "/accept_legal" && pp != "/last_policy" && !pp.include?("/privacypolicies") && pp != "/about" && pp != "/contact" && pp != "/signout"
      if Privacypolicy.where(:online => true).count > 0
        render 'users/read_legal' and return
      else # If no policy at all, we automatically mark it as read
        current_user.update_attribute(:last_policy_read, true)
      end
    end
  end
  
  # Check that the user is signed in, and if not then redirect to the page "Please sign in to see this page"
  def signed_in_user
    unless @signed_in
      store_location
      flash[:danger] = "Vous devez être connecté pour accéder à cette page."
      redirect_to signin_path
    end
  end
  
  # In the case of a compromising page (like "delete a user"), we don't allow a redirection (to avoid hacks)
  def signed_in_user_danger
    unless @signed_in
      render 'errors/access_refused' and return
    end
  end
  
  # Check that the user is signed out
  def signed_out_user
    if @signed_in
      redirect_to root_path
    end
  end

  # Check that current user is not in the skin of somebody else
  def notskin_user
    if @signed_in && current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_back(fallback_location: root_path)
    end
  end

  # Check that current user is an admin
  def admin_user
    if !@signed_in || !current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is not an admin (i.e. is a student)
  def non_admin_user
    if !@signed_in || current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end

  # Check that current user is a root
  def root_user
    if !@signed_in || !current_user.sk.root
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is an admin or corrector
  def corrector_user
    if !@signed_in || (!current_user.sk.admin && !current_user.sk.corrector)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is a corrector (or admin) that can correct the submission
  def user_that_can_correct_submission
    unless @signed_in && (current_user.sk.admin || (current_user.sk.corrector && current_user.sk.pb_solved?(@problem) && current_user.sk != @submission.user))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user can update @chapter (that must be defined)
  def user_that_can_update_chapter
    unless (@signed_in && (current_user.sk.admin? || (!@chapter.online? && current_user.sk.creating_chapters.exists?(@chapter.id))))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user can see @problem (that must be defined)
  def user_that_can_see_problem
    if !@problem.can_be_seen_by(current_user.sk, @no_new_submission)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user can see @subject (that must be defined)
  def user_that_can_see_subject
    if !@subject.can_be_seen_by(current_user.sk)
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user can write a submission
  def user_that_can_write_submission
    if !current_user.sk.can_write_submission?
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is an organizer of @contest (that must be defined)
  def organizer_of_contest
    if !(@signed_in && @contest.is_organized_by(current_user.sk))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is a root or an organizer of @contest (that must be defined)
  def organizer_of_contest_or_root
    if !(@signed_in && @contest.is_organized_by_or_root(current_user.sk))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that current user is an admin or an organizer of @contest (that must be defined)
  def organizer_of_contest_or_admin
    if !(@signed_in && @contest.is_organized_by_or_admin(current_user.sk))
      render 'errors/access_refused' and return
    end
  end
  
  # Check that an object exists: should be used as "return if check_nil_object(...)"
  def check_nil_object(object)
    if object.nil?
      render 'errors/access_refused' and return true
    end
    return false
  end
  
  # Check that an object is ONLINE: should be used as "return if check_offline_object(...)"
  def check_offline_object(object)
    if !object.online
      render 'errors/access_refused' and return true
    end
    return false
  end
  
  # Check that an object if OFFLINE: should be used as "return if check_online_object(...)"
  def check_online_object(object)
    if object.online
      render 'errors/access_refused' and return true
    end
    return false
  end
  
  # Swap the positions of two objects
  def swap_position(a, b)
    if !a.nil? && !b.nil? && a != b
      x = a.position
      y = b.position
      a.update_attribute(:position, y)
      b.update_attribute(:position, x)
      if x > y
        return " vers le haut"
      else
        return " vers le bas"
      end
    end
    return ""
  end

  # Method called from several locations to create files from a form
  def create_files
    attach = Array.new
    totalsize = add_new_files(attach)
    return [] if !@error_message.empty?
    check_files_total_size(totalsize)
    destroy_files(attach) and return [] if !@error_message.empty?
    return attach
  end

  # Method called from several locations to update files from a form: we should be sure that the object is valid
  def update_files(object)
    totalsize = 0
    postfix = (params["postfix"].nil? ? "" : params["postfix"]);
    object.myfiles.each do |f|
      if params["prevFile#{postfix}_#{f.id}".to_sym].nil?
        f.destroy # Should automatically purge the file
      else
        totalsize = totalsize + f.file.blob.byte_size
      end
    end

    object.fakefiles.each do |f|
      if params["prevFakeFile#{postfix}_#{f.id}".to_sym].nil?
        f.destroy
      end
    end
    
    attach = Array.new
    totalsize += add_new_files(attach)
    return [] if !@error_message.empty?
    check_files_total_size(totalsize)
    destroy_files(attach) and return [] if !@error_message.empty?
    
    attach_files(attach, object)
  end
  
  # Helper method called by create_files and update_files to create all new files
  def add_new_files(attach)
    totalsize = 0
    k = 1
    postfix = (params["postfix"].nil? ? "" : params["postfix"]);
    while !params["hidden#{postfix}_#{k}".to_sym].nil? do
      if !params["file#{postfix}_#{k}".to_sym].nil?
        attach.push(Myfile.new(:file => params["file#{postfix}_#{k}".to_sym]))
        if !attach.last.save
          attach.pop()
          destroy_files(attach)
          nom = params["file#{postfix}_#{k}".to_sym].original_filename
          @error_message = "Votre pièce jointe '#{nom}' ne respecte pas les conditions."
          return 0;
        end
        totalsize = totalsize + attach.last.file.blob.byte_size
      end
      k = k+1
    end
    
    return totalsize
  end
  
  # Helper method called by create_files and update_files to check maximum total size of files
  def check_files_total_size(totalsize)
    limit = (Rails.env.test? ? 15.kilobytes : 5.megabytes) # In test mode we put a very small limit
    limit_str = (Rails.env.test? ? "15 ko" : "5 Mo")
    if totalsize > limit
      @error_message = "Vos pièces jointes font plus de #{limit_str} au total (#{(totalsize.to_f/1.megabyte).round(3)} Mo)"
    end
  end
  
  # Method called from several locations to attach the uploaded files to an object
  def attach_files(attach, object)
    attach.each do |a|
      a.update_attribute(:myfiletable, object)
    end
  end

  # Method called from several locations to delete some temporarily uploaded files (because of another error)
  def destroy_files(attach)
    attach.each do |a|
      a.destroy # Should automatically purge the file
    end
  end
  
  # Check if some test just got finished
  def check_takentests
    time_now = DateTime.now.to_i
    Takentestcheck.all.each do |c|
      t = c.takentest
      if t.finished?
        c.destroy # Should not happen in theory
      else
        debut = t.taken_time.to_i
        fin = debut + t.virtualtest.duration*60
        if fin < time_now
          c.destroy
          t.finished!
          u = t.user
          v = t.virtualtest
          v.problems.each do |p|
            p.submissions.where(user_id: u.id, intest: true).each do |s|
              s.update_attribute(:visible, true)
            end
          end
        end
      end
    end
  end
  
  # Check if a contest problem just started or ended (done only when charging a contest related page)
  def check_contests
    date_now = DateTime.now
    # Note: Problems in Contestproblemcheck are also used in contest.rb to check problems for which an email or forum subject must be created
    Contestproblemcheck.all.order(:id).each do |c|
      p = c.contestproblem
      if p.not_started_yet? # Contest is online but problem is not published yet
        if p.start_time <= date_now
          p.in_progress!
        end
      end
      if p.in_progress? # Problem has started but not ended
        if p.end_time <= date_now
          p.in_correction!
          contest = p.contest
          if contest.contestproblems.where(:status => [:not_started_yet, :in_progress]).count == 0 # All problems of the contest are finished: mark the contest as finished
            contest.in_correction!
          end
        end
      end
      if p.at_least(:in_correction) && p.all_reminders_sent? # Avoid to delete if reminders were not sent yet
        c.destroy
      end
    end
  end
  
  # Method called from different locations to recompute all the contest scores
  def compute_new_contest_rankings(contest)
    # Find all users with a score > 0 in the contest
    userset = Set.new
    probs = contest.contestproblems.where(:status => [:corrected, :in_recorrection])
    probs.each do |p|
      p.contestsolutions.where("score > 0 AND official = ?", false).each do |s|
        userset.add(s.user_id)
      end
    end
    
    # Delete from Contestscore the users who don't have a score (can happen if we modify a score to 0)
    @contest.contestscores.each do |s|
      if !userset.include?(s.user_id)
        s.destroy
      end
    end
    
    # Compute the scores of all users
    scores = Array.new
    userset.each do |u|
      score = 0
      hm = false
      probs.each do |p|
        sol = p.contestsolutions.where(:user_id => u).first
        if !sol.nil?
          score = score + sol.score
          if sol.score == 7
            hm = true
          end
        end
      end
      scores.push([-score, u, hm])
    end
    
    # Sort the scores
    scores.sort!    
    
    # Compute the ranking (and maybe medal) of each user
    give_medals = (contest.medal && contest.gold_cutoff > 0)
    prevscore = -1
    i = 1
    rank = 0
    scores.each do |a|
      score = -a[0]
      u = a[1]
      hm = a[2]
      if score != prevscore
        rank = i
        prevscore = score
      end
      cs = Contestscore.where(:contest => @contest, :user_id => u).first
      if cs.nil?
        cs = Contestscore.new(:contest => contest, :user_id => u)
      end
      cs.rank = rank
      cs.score = score
      if give_medals
        if score >= contest.gold_cutoff
          cs.medal = :gold_medal
        elsif score >= contest.silver_cutoff
          cs.medal = :silver_medal
        elsif score >= contest.bronze_cutoff
          cs.medal = :bronze_medal
        elsif hm
          cs.medal = :honourable_mention
        else
          cs.medal = :no_medal
        end
      else
        cs.medal = :undefined_medal
      end
      cs.save
      i = i+1
    end
    
    # Change some details of the contest
    contest.update_attribute(:num_participants, scores.size)
    contest_fully_corrected = (contest.contestproblems.where(:status => [:not_started_yet, :in_progress, :in_correction]).count == 0)
    if contest_fully_corrected
      contest.completed!
    end
  end
  
end

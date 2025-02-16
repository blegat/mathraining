#encoding: utf-8

class CustomCSRFStrategy
  def initialize(controller)
    @controller = controller
  end

  def handle_unverified_request
    @controller.set_invalid_csrf_token
  end
end

class ApplicationController < ActionController::Base
  include ApplicationHelper
  include SessionsHelper
  
  protect_from_forgery with: CustomCSRFStrategy
  before_action :error_if_invalid_csrf_token
  before_action :start_or_stop_benchmark
  before_action :load_global_variables
  before_action :check_under_maintenance
  before_action :has_consent
  before_action :check_takentests
  
  # Called from CustomCSRFStrategy when an invalid token is detected
  def set_invalid_csrf_token
    @invalid_csrf_token = true
  end
  
  private
  
  # Error in case of invalid CSRF token: this method is sometimes skipped with skip_before_action
  # and replaced by something else so that users don't lose what they wrote
  def error_if_invalid_csrf_token
    if @invalid_csrf_token
      flash[:danger] = get_csrf_error_message
      referrer_url = URI.parse(request.referrer) rescue URI.parse(root_url)
      redirect_to referrer_url.to_s
    end
  end
  
  # Deal with start_benchmark and stop_benchmark, to benchmark the loading time of a page
  def start_or_stop_benchmark
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
  end
  
  # Create some global variables that are always needed
  def load_global_variables
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
  
  # When doing big changes on the server
  def check_under_maintenance
    if @under_maintenance
      flash[:info] = @under_maintenance_message
      if !signed_in? || !current_user_no_skin.root?
        redirect_to root_path if request.path != "/"
      end
    end
  end
  
  # Check that the user consented to the last policy
  def has_consent
    pp = request.fullpath.to_s
    if signed_in? && !current_user_no_skin.last_policy_read && pp != "/accept_legal" && pp != "/last_policy" && !pp.include?("/privacypolicies") && pp != "/about" && pp != "/contact" && pp != "/signout" && (Rails.env.production? || !pp.include?("/fast_sign_in"))
      if Privacypolicy.where(:online => true).count > 0
        render 'users/read_legal'
      else # If no policy at all, we automatically mark it as read
        current_user_no_skin.update(:last_policy_read => true, :consent_time => DateTime.now)
      end
    end
  end
  
  ########## HELPER METHODS ##########
  
  # Message to show when an invalid CSRF token is detected
  def get_csrf_error_message
    return "Votre session a expiré et vos données n'ont pas pu être enregistrées. Merci de réessayer."
  end
  
  # Swap the positions of two objects
  def swap_position(a, b)
    return "" if a.nil? || b.nil? || a == b
    x = a.position
    y = b.position
    a.update_attribute(:position, y)
    b.update_attribute(:position, x)
    return (x > y ? " vers le haut" : " vers le bas")
  end
  
  # Render a view after having added an error to an object if needed
  def render_with_error(view, obj = nil, error = nil)
    obj.errors.add(:base, error) unless obj.nil? || error.nil?
    render view
  end
  
  ########## CHECK METHODS ##########
  
  # Check that the user is signed in, and if not then redirect to the page "Please sign in to see this page"
  def signed_in_user
    unless signed_in?
      flash.now[:danger] = "Vous devez être connecté pour accéder à cette page."
      render 'sessions/new'
    end
  end
  
  # In the case of a compromising page (like "delete a user"), we don't allow a redirection (to avoid hacks)
  def signed_in_user_danger
    unless signed_in?
      render 'errors/access_refused'
    end
  end
  
  # Check that the user is signed out
  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end

  # Check that current user is not in the skin of somebody else
  def user_not_in_skin
    if in_skin?
      if request.format.html?
        flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
        redirect_back(fallback_location: root_path)
      elsif request.format.js?
        render :js => 'alert("Vous ne pouvez pas effectuer cette action dans la peau de quelqu\'un.");'
      end
    end
  end

  # Check that current user is an admin
  def admin_user
    if !signed_in? || !current_user.admin?
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is not an admin (i.e. is a student)
  def non_admin_user
    if !signed_in? || current_user.admin?
      render 'errors/access_refused'
    end
  end

  # Check that current user is a root
  def root_user
    if !signed_in? || !current_user.root?
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is an admin or corrector
  def corrector_user
    if !signed_in? || (!current_user.admin? && !current_user.corrector?)
      render 'errors/access_refused'
    end
  end
  
  # Check that current user can write a submission
  def user_can_write_submission
    if !current_user.can_write_submission?
      render 'errors/access_refused'
    end
  end
  
  # Check that an object exists: should be used as "return if check_nil_object(...)"
  def check_nil_object(object)
    if object.nil?
      render 'errors/access_refused'
      return true
    end
    return false
  end
  
  # Check that an object is ONLINE: should be used as "return if check_offline_object(...)"
  def check_offline_object(object)
    if !object.online
      render 'errors/access_refused'
      return true
    end
    return false
  end
  
  # Check that an object if OFFLINE: should be used as "return if check_online_object(...)"
  def check_online_object(object)
    if object.online
      render 'errors/access_refused'
      return true
    end
    return false
  end
  
  ########## GENERAL TEST STATUS CHECK METHOD ##########
  
  # Check if some test just got finished
  def check_takentests
    return unless request.format.html?
    time_now = DateTime.now.to_i
    Takentestcheck.includes(:takentest, takentest: :virtualtest).all.each do |c|
      takentest = c.takentest
      c.destroy and next if takentest.finished? # Should not happen in theory
      virtualtest = takentest.virtualtest
      fin = takentest.taken_time.to_i + virtualtest.duration * 60
      next if fin >= time_now # Not finished yet
      c.destroy
      takentest.finished!
      user = takentest.user
      virtualtest.problems.each do |p|
        p.submissions.where(user_id: user.id, intest: true).each do |s|
          s.update_attribute(:status, :waiting)
          Following.create(:submission => s, :user => User.where(:root => true).order(:id).last, :kind => :reservation) if user.has_auto_reserved_sanction
        end
      end
    end
  end
end

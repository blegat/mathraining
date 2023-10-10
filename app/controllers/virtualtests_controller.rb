#encoding: utf-8
class VirtualtestsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online, :begin_test]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :put_online, :destroy]
  before_action :non_admin_user, only: [:begin_test]
  
  before_action :get_virtualtest, only: [:show, :edit, :update, :destroy]
  before_action :get_virtualtest2, only: [:begin_test, :put_online]
  
  before_action :has_access, only: [:begin_test]
  before_action :online_test, only: [:begin_test]
  before_action :user_that_can_write_submission, only: [:begin_test]
  before_action :can_begin, only: [:begin_test]
  before_action :can_be_online, only: [:put_online]
  before_action :offline_test, only: [:destroy]
  before_action :in_test, only: [:show]

  # Show all virtualtests (that can be seen)
  def index
    flash.now[:info] = @no_new_submission_message if @no_new_submission
  end

  # Show one virtualtest
  def show
  end

  # Create a virtualtest (show the form)
  def new
    @virtualtest = Virtualtest.new
  end

  # Update a virtualtest (show the form)
  def edit
  end

  # Create a virtualtest (send the form)
  def create
    @virtualtest = Virtualtest.new
    @virtualtest.duration = params[:virtualtest][:duration]
    @virtualtest.online = false

    nombre = 0
    loop do
      nombre = rand(100)
      break if Virtualtest.where(:number => nombre).count == 0
    end
    @virtualtest.number = nombre

    if @virtualtest.save
      flash[:success] = "Test virtuel ajouté."
      redirect_to virtualtests_path
    else
      render 'new'
    end
  end

  # Update a virtualtest (send the form)
  def update
    @virtualtest.duration = params[:virtualtest][:duration]
    if @virtualtest.save
      flash[:success] = "Test virtuel modifié."
      redirect_to virtualtests_path
    else
      render 'edit'
    end
  end

  # Delete a virtualtest
  def destroy
    @virtualtest.problems.each do |p|
      p.virtualtest_id = 0
      p.position = 0
      p.save
    end
    @virtualtest.destroy
    flash[:success] = "Test virtuel supprimé."
    redirect_to virtualtests_path
  end

  # Put a virtualtest online
  def put_online
    @virtualtest.online = true
    @virtualtest.save
    flash[:success] = "Test virtuel mis en ligne."
    redirect_to virtualtests_path
  end

  # Begin a virtualtest
  def begin_test
    t = Takentest.create(:user => current_user.sk, :virtualtest => @virtualtest, :status => :in_progress, :taken_time => DateTime.now)    
    Takentestcheck.create(:takentest => t)    
    redirect_to @virtualtest
  end

  private
  
  ########## GET METHODS ##########

  # Get the virtualtest
  def get_virtualtest
    @virtualtest = Virtualtest.find_by_id(params[:id])
    return if check_nil_object(@virtualtest)
  end

  # Get the virtualtest (v2)
  def get_virtualtest2
    @virtualtest = Virtualtest.find_by_id(params[:virtualtest_id])
    return if check_nil_object(@virtualtest)
  end
  
  ########## CHECK METHODS ##########
  
  # Check that current user is currently doing the virtualtest
  def in_test
    virtualtest_status = current_user.sk.test_status(@virtualtest)
    render 'errors/access_refused' and return if virtualtest_status == "not_started"
    redirect_to virtualtests_path and return if virtualtest_status == "finished" # Smoothly redirect because it can happen when timer stops
  end

  # Check that current user has access to the virtualtest
  def has_access
    if !has_enough_points
      render 'errors/access_refused' and return
    end
    visible = true
    @virtualtest.problems.each do |p|
      p.chapters.each do |c|
        visible = false if !current_user.sk.chap_solved?(c)
      end
    end
    if !visible
      render 'errors/access_refused' and return
    end
  end

  # Check that the virtualtest is online
  def online_test
    return if check_offline_object(@virtualtest)
  end
  
  # Check that the vitualtest is offline
  def offline_test
    return if check_online_object(@virtualtest)
  end

  # Check that the virtual test can be put online
  def can_be_online
    nb_prob = 0
    can_online = true
    @virtualtest.problems.each do |p|
      can_online = false if !p.online?
      nb_prob = nb_prob + 1
    end
    redirect_to virtualtests_path if !can_online || nb_prob == 0
  end

  # Check that current user can start the test
  def can_begin
    redirect_to virtualtests_path if @no_new_submissions
    if current_user.sk.test_status(@virtualtest) != "not_started"
      redirect_to virtualtests_path
    elsif Takentest.where(:user => current_user.sk, :status => :in_progress).count > 0
      flash[:danger] = "Vous avez déjà un test virtuel en cours !"
      redirect_to virtualtests_path
    end
  end
end

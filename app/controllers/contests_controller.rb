#encoding: utf-8
class ContestsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online]
  before_action :admin_user, only: [:new, :create, :destroy, :put_online]
  
  before_action :check_contests, only: [:index, :show] # Defined in application_controller.rb
  
  before_action :get_contest, only: [:show, :edit, :update, :destroy]
  before_action :get_contest2, only: [:put_online, :cutoffs, :define_cutoffs]
  
  before_action :organizer_of_contest_or_admin, only: [:edit, :update, :cutoffs, :define_cutoffs]
  before_action :can_see_contest, only: [:show]
  before_action :can_be_online, only: [:put_online]
  before_action :offline_contest, only: [:destroy]
  before_action :can_define_cutoffs, only: [:cutoffs, :define_cutoffs]

  # Show all the contests
  def index
  end

  # Show one contest
  def show
  end
 
  # Choose the cutoffs for a contest (show the form)
  def cutoffs
  end
  
  # Choose the cutoffs for a contest (send the form)
  def define_cutoffs
    @contest.bronze_cutoff = params[:bronze_cutoff].to_i
    @contest.silver_cutoff = params[:silver_cutoff].to_i
    @contest.gold_cutoff = params[:gold_cutoff].to_i
    if @contest.save
      compute_new_contest_rankings(@contest)
      flash[:success] = "Les médailles ont été distribuées !"
    else
      flash[:danger] = error_list_for(@contest)
    end
    redirect_to @contest
  end

  # Create a contest (show the form)
  def new
    @contest = Contest.new
  end

  # Update a contest (show the form)
  def edit
  end

  # Create a contest (send the form)
  def create
    @contest = Contest.new(params.require(:contest).permit(:number, :description, :medal))

    if @contest.save
      flash[:success] = "Concours ajouté."
      redirect_to @contest
    else
      render 'new'
    end
  end

  # Update a contest (send the form)
  def update
    if @contest.update(params.require(:contest).permit(:number, :description, :medal))
      flash[:success] = "Concours modifié."
      redirect_to contest_path
    else
      render 'edit'
    end
  end

  # Delete a contest
  def destroy
    @contest.destroy
    flash[:success] = "Concours supprimé."
    redirect_to contests_path
  end

  # Put a contest online
  def put_online
    @contest.in_progress!
    date_in_one_day = 1.day.from_now
    @contest.contestproblems.order(:number, :id).each do |p|
      p.not_started_yet!
      if p.start_time <= date_in_one_day # Problem starts in less than one day: there will be no post on the forum one day before
        p.early_reminder_sent!
      end
      Contestproblemcheck.create(:contestproblem => p)
    end
    
    # Create the subject on the forum for this new contest
    create_forum_subject(@contest)

    flash[:success] = "Concours mis en ligne."
    redirect_to contests_path
  end

  private

  ########## GET METHODS ##########

  # Get the contest
  def get_contest
    @contest = Contest.find_by_id(params[:id])
    return if check_nil_object(@contest)
  end
  
  # Get the contest (v2)
  def get_contest2
    @contest = Contest.find_by_id(params[:contest_id])
    return if check_nil_object(@contest)
  end
  
  ########## CHECK METHODS ##########
  
  # Check if current user can see the contest
  def can_see_contest
    if (@contest.in_construction? && !(@signed_in && @contest.is_organized_by_or_admin(current_user.sk)))
      render 'errors/access_refused' and return
    end
  end

  # Check if the contest can be put online
  def can_be_online
    date_in_one_hour = 1.hour.from_now
    if @contest.contestproblems.count == 0
      flash[:danger] = "Un concours doit contenir au moins un problème !"
      redirect_to @contest
    elsif @contest.contestproblems.first.start_time < date_in_one_hour
      unless Rails.env.development?
        flash[:danger] = "Un concours ne peut être mis en ligne moins d'une heure avant le premier problème."
        redirect_to @contest
      end
      flash[:info] = "Un concours ne peut être mis en ligne moins d'une heure avant le premier problème (en production)." if Rails.env.development?
    end
  end

  # Check that the contest is offline
  def offline_contest
    if !@contest.in_construction?
      render 'errors/access_refused' and return
    end
  end
  
  # Check if cutoffs can be defined for this contest
  def can_define_cutoffs
    if !@contest.completed? || !@contest.medal || (@contest.gold_cutoff > 0 && !current_user.sk.root)
      render 'errors/access_refused' and return
    end
  end

  ########## HELPER METHODS ##########

  # Helper method to create the forum subject for a contest
  def create_forum_subject(contest)
    s = Subject.create(:contest              => contest,
                       :user_id              => 0,
                       :title                => "Concours ##{contest.number}",
                       :content              => helpers.get_new_contest_forum_message(contest),
                       :last_comment_time    => DateTime.now,
                       :last_comment_user_id => 0,
                       :category             => Category.where(:name => "Mathraining").first)
  end
end

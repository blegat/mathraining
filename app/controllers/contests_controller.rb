#encoding: utf-8
class ContestsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online]
  before_action :admin_user, only: [:new, :create, :destroy, :put_online]
  before_action :check_contests, only: [:index, :show] # Defined in application_controller.rb
  before_action :get_contest, only: [:show, :edit, :update, :destroy]
  before_action :get_contest2, only: [:put_online, :cutoffs, :define_cutoffs]
  before_action :is_organizer_or_admin, only: [:edit, :update, :cutoffs, :define_cutoffs]
  before_action :can_see, only: [:show]
  before_action :can_be_online, only: [:put_online]
  before_action :delete_online, only: [:destroy]
  before_action :can_define_cutoffs, only: [:cutoffs, :define_cutoffs]

  # Voir tous les concours
  def index
  end

  # Montrer un concours
  def show
  end
 
  # Choisir les médailles 
  def cutoffs
  end
  
  # Choisir les médailles 2
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

  # Créer un concours
  def new
    @contest = Contest.new
  end

  # Editer un concours
  def edit
  end

  # Créer un concours 2
  def create
    @contest = Contest.new(params.require(:contest).permit(:number, :description, :medal))

    if @contest.save
      flash[:success] = "Concours ajouté."
      redirect_to @contest
    else
      render 'new'
    end
  end

  # Editer un concours 2
  def update
    if @contest.update_attributes(params.require(:contest).permit(:number, :description, :medal))
      flash[:success] = "Concours modifié."
      redirect_to contest_path
    else
      render 'edit'
    end
  end

  # Supprimer un concours
  def destroy
    @contest.destroy
    flash[:success] = "Concours supprimé."
    redirect_to contests_path
  end

  # Mettre en ligne
  def put_online
    @contest.status = 1
    @contest.save
    date_in_one_day = 1.day.from_now
    @contest.contestproblems.order(:number, :id).each do |p|
      p.status = 1
      if p.start_time <= date_in_one_day # Problem start in less than one day: there will be no post on the forum one day before
        p.reminder_status = 1
      end
      p.save
      c = Contestproblemcheck.new
      c.contestproblem = p
      c.save
    end
    # On crée le sujet de forum correspondant
    
    create_forum_subject(@contest)

    flash[:success] = "Concours mis en ligne."
    redirect_to contests_path
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère
  def get_contest
    @contest = Contest.find_by_id(params[:id])
    return if check_nil_object(@contest)
  end
  
  # On récupère
  def get_contest2
    @contest = Contest.find_by_id(params[:contest_id])
    return if check_nil_object(@contest)
  end
  
  def is_organizer_or_admin
    if !@contest.is_organized_by_or_admin(current_user)
      render 'errors/access_refused' and return
    end
  end
  
  # Si le concours n'est pas en ligne et on n'est ni organisateur ni administrateur, on ne peut pas voir le concours
  def can_see
    if (@contest.status == 0 && (!@signed_in || !@contest.is_organized_by_or_admin(current_user)))
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le concours peut être en ligne
  def can_be_online
    date_in_one_hour = 1.hour.from_now
    if @contest.contestproblems.count == 0
      flash[:danger] = "Un concours doit contenir au moins un problème !"
      redirect_to @contest
    elsif @contest.contestproblems.first.start_time < date_in_one_hour
      if !Rails.env.development?
        flash[:danger] = "Un concours ne peut être mis en ligne moins d'une heure avant le premier problème."
        redirect_to @contest
      else
        flash[:info] = "Un concours ne peut être mis en ligne moins d'une heure avant le premier problème (en production)."
      end
    end
  end

  # Vérifie qu'on ne supprime pas un concours en ligne
  def delete_online
    if @contest.status > 0
      render 'errors/access_refused' and return
    end
  end
  
  # Vérifie qu'on peut définir les cutoffs pour les médailles
  def can_define_cutoffs
    if @contest.status != 3 || !@contest.medal || (@contest.gold_cutoff > 0 && !current_user.sk.root)
      render 'errors/access_refused' and return
    end
  end

  # Créer le sujet de Forum associé au concours
  def create_forum_subject(contest)
    s = Subject.new
    s.contest = contest
    s.user_id = 0
    s.title = "Concours ##{contest.number}"
    s.content = helpers.get_new_contest_forum_message(contest)
    
    Category.all.each do |c|
      if c.name == "Mathraining"
        s.category = c
      end
    end
    
    s.last_comment_time = DateTime.now
    s.last_comment_user_id = 0 # Message automatique
    s.save
  end
end

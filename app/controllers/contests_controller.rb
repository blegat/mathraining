#encoding: utf-8
class ContestsController < ApplicationController
  before_action :signed_in_user, only: [:new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online, :add_organizer, :remove_organizer]
  before_action :admin_user, only: [:new, :create, :destroy, :put_online, :add_organizer, :remove_organizer]
  before_action :get_contest, only: [:show, :edit, :update, :destroy]
  before_action :get_contest2, only: [:put_online, :add_organizer, :remove_organizer]
  before_action :is_organizer_or_admin, only: [:edit, :update]
  before_action :can_see, only: [:show]
  before_action :can_be_online, only: [:put_online]
  before_action :delete_online, only: [:destroy]

  # Voir tous les concours
  def index
  end

  # Montrer un concours
  def show
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
  
  # Ajouter un organisateur
  def add_organizer
    contestorganization = Contestorganization.new
    contestorganization.contest = @contest
    contestorganization.user_id = params[:user_id]
    if !contestorganization.save
      flash[:danger] = "Une erreur est survenue."
    end
    redirect_to @contest
  end
  
  def remove_organizer
    @contest.organizers.delete(params[:user_id])
    redirect_to @contest
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère
  def get_contest
    @contest = Contest.find_by_id(params[:id])
    if @contest.nil?
      render 'errors/access_refused' and return
    end
  end
  
  # On récupère
  def get_contest2
    @contest = Contest.find_by_id(params[:contest_id])
    if @contest.nil?
      render 'errors/access_refused' and return
    end
  end
  
  def is_organizer_or_admin
    if !@contest.is_organized_by_or_admin(current_user)
      render 'errors/access_refused' and return
    end
  end
  
  # Si le concours n'est pas en ligne et on n'est ni organisateur ni adminitrateur, on ne peut pas voir le concours
  def can_see
    if (@contest.status == 0 && @signed_in && !@contest.is_organized_by_or_admin(current_user))
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
      if Rails.env.production?
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

  
  def create_forum_subject(contest)
    s = Subject.new
    s.contest = contest
    s.user_id = 0
    s.title = "Concours ##{contest.number}"
    text = "Le [url=" + contest_url(contest) + "]Concours ##{contest.number}[/url], organisé par "
    nb = contest.organizers.count
    i = 0
    contest.organizers.order(:last_name, :first_name).each do |o|
      text = text + "[b]" + o.name + "[/b]"
      i = i+1
      if i == nb-1
        text = text + " et "
      elsif i < nb-1
        text = text + ", "
      end
    end
    text = text + ", vient d'être mis en ligne. Il comporte [b]" + contest.contestproblems.count.to_s + " problème#{'s' if contest.contestproblems.count > 1}[/b] et démarrera le [b]" + write_date_only(contest.contestproblems.order(:number).first.start_time) + "[/b]. "
    text = text + " En voici la description :\n\r\n\r" + contest.description + "\n\r\n\r"
    contest.contestproblems.order(:number).each do |p|
      text = text + "Le Problème #" + p.number.to_s + " sera ouvert aux solutions du " + write_date_with_link_forum(p.start_time, contest, p) + " au " + write_date_with_link_forum(p.end_time, contest, p) + ".\n\r"
    end
    
    text = text + "Ces dates sont normalement définitives. Si toutefois elles venaient à changer alors une annonce sera faite pour prévenir tout le monde.\n\r\n\r"
    text = text + "Pour chaque problème du concours, un message automatique sera publié sur ce forum un jour avant sa publication, au moment de sa publication, et après sa correction. Si vous désirez également recevoir un rappel par e-mail un jour avant la publication de chaque problème, vous pouvez cliquer sur 'Suivre ce concours' en haut à droite de [url=" + contest_url(contest) + "]cette page[/url].\n\r\n\r"
    if contest.medal?
      text = text + "Des médailles et mentions honorables seront attribuées à la fin de ce concours.\n\r\n\r"
    else
      text = text + "Il n'y aura pas de médailles et mentions honorables pour ce concours.\n\r\n\r"
    end
    text = text + "Ce sujet peut être utilisé pour échanger vos commentaires sur le concours, mais il vous est demandé de ne pas vous entraider ;-)\n\r\n\r"
    text = text + "Bonne chance à tous, et surtout bon amusement ! :-)"
    s.content = text
    
    Category.all.each do |c|
      if c.name == "Mathraining"
        s.category = c
      end
    end
    
    s.lastcomment = DateTime.now
    s.save
  end
end

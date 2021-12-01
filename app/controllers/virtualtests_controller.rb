#encoding: utf-8
class VirtualtestsController < ApplicationController
  before_action :signed_in_user, only: [:show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online, :begin_test]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :put_online, :destroy]
  before_action :get_virtualtest, only: [:show, :edit, :update, :destroy]
  before_action :get_virtualtest2, only: [:begin_test, :put_online]
  before_action :has_access, only: [:show, :begin_test]
  before_action :online_test, only: [:show, :begin_test]
  before_action :can_begin, only: [:begin_test]
  before_action :can_be_online, only: [:put_online]
  before_action :delete_online, only: [:destroy]
  before_action :enough_points, only: [:show, :begin_test]
  before_action :in_test, only: [:show]

  # Voir tous les tests virtuels
  def index
  end

  # Montrer un test virtuel
  def show
  end

  # Créer un test virtuel
  def new
    @virtualtest = Virtualtest.new
  end

  # Editer un test virtuel
  def edit
  end

  # Créer un test virtuel 2
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

  # Editer un test virtuel 2
  def update
    @virtualtest.duration = params[:virtualtest][:duration]
    if @virtualtest.save
      flash[:success] = "Test virtuel modifié."
      redirect_to virtualtests_path
    else
      render 'edit'
    end
  end

  # Supprimer un test virtuel
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

  # Mettre en ligne
  def put_online
    @virtualtest.online = true
    @virtualtest.save
    flash[:success] = "Test virtuel mis en ligne."
    redirect_to virtualtests_path
  end

  # Commencer le test
  def begin_test
    t = Takentest.new
    t.user = current_user.sk
    t.virtualtest = @virtualtest
    t.status = 0
    t.taken_time = DateTime.now
    t.save
    
    c = Takentestcheck.new
    c.takentest = t
    c.save
    
    redirect_to @virtualtest
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère
  def get_virtualtest
    @virtualtest = Virtualtest.find_by_id(params[:id])
    return if check_nil_object(@virtualtest)
  end

  def get_virtualtest2
    @virtualtest = Virtualtest.find_by_id(params[:virtualtest_id])
    return if check_nil_object(@virtualtest)
  end
  
  # Vérifie que le test est en cours
  def in_test
    redirect_to virtualtests_path if current_user.sk.admin || current_user.sk.status(@virtualtest.id) != 0
  end

  # Vérifie qu'on a accès à ce test
  def has_access
    if !current_user.sk.admin?
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
  end

  # Vérifie que le test est en ligne ou qu'on est admin
  def online_test
    if !@virtualtest.online && !current_user.sk.admin
      render 'errors/access_refused' and return
    end
  end

  # Vérifie que le test peut être en ligne
  def can_be_online
    nb_prob = 0
    can_online = true
    @virtualtest.problems.each do |p|
      can_online = false if !p.online?
      nb_prob = nb_prob + 1
    end
    redirect_to virtualtests_path if !can_online || nb_prob == 0
  end

  # Vérifie qu'on peut commencer le test
  def can_begin
    if current_user.sk.status(@virtualtest) >= 0
      redirect_to virtualtests_path
    elsif Takentest.where(user_id: current_user.sk.id, status: 0).count > 0
      flash[:danger] = "Vous avez déjà un test virtuel en cours !"
      redirect_to virtualtests_path
    end
  end

  # Vérifie qu'on ne supprime pas un test en ligne
  def delete_online
    if @virtualtest.online
      render 'errors/access_refused' and return
    end
  end
end

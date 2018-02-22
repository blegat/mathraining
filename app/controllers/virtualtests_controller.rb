#encoding: utf-8
class VirtualtestsController < ApplicationController
  before_action :signed_in_user, only: [:index, :show, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy, :put_online, :begin_test]
  before_action :admin_user, only: [:new, :create, :edit, :update, :destroy, :put_online, :destroy]
  before_action :recup, only: [:show, :destroy]
  before_action :recup2, only: [:begin_test]
  before_action :has_access, only: [:show, :begin_test]
  before_action :online_test, only: [:show, :begin_test]
  before_action :can_begin, only: [:begin_test]
  before_action :can_be_online, only: [:put_online]
  before_action :delete_online, only: [:destroy]
  before_action :enough_points, only: [:show, :begin_test]

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
    @virtualtest = Virtualtest.find(params[:id])
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
      redirect_to @virtualtest
    else
      render 'new'
    end
  end

  # Editer un test virtuel 2
  def update
    @virtualtest = Virtualtest.find(params[:id])
    @virtualtest.duration = params[:virtualtest][:duration]
    if @virtualtest.save
      flash[:success] = "Test virtuel ajouté."
      redirect_to @virtualtest
    else
      render 'new'
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
    redirect_to virtualtests_path
  end

  # Mettre en ligne
  def put_online
    @virtualtest.online = true
    @virtualtest.save
    redirect_to @virtualtest
  end

  # Commencer le test
  def begin_test
    t = Takentest.new
    t.user = current_user.sk
    t.virtualtest = @virtualtest
    t.status = 0
    t.takentime = DateTime.now
    t.save
    redirect_to @virtualtest
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère
  def recup
    @virtualtest = Virtualtest.find(params[:id])
  end

  def recup2
    @virtualtest = Virtualtest.find(params[:virtualtest_id])
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
      redirect_to root_path if !visible
    end
  end

  # Vérifie que le test est en ligne ou qu'on est admin
  def online_test
    redirect_to root_path if !@virtualtest.online && !current_user.sk.admin
  end

  # Vérifie que le test peut être en ligne
  def can_be_online
    @virtualtest = Virtualtest.find(params[:virtualtest_id])
    nb_prob = 0
    can_online = true
    @virtualtest.problems.each do |p|
      can_online = false if !p.online?
      nb_prob = nb_prob + 1
    end
    redirect_to @virtualtest if !can_online || nb_prob == 0
  end

  # Vérifie qu'on peut commencer le test
  def can_begin
    if current_user.sk.status(@virtualtest) >= 0
      redirect_to @virtualtest
    elsif Takentest.where(user_id: current_user.sk.id, status: 0).count > 0
      flash[:danger] = "Vous avez déjà un test virtuel en cours!"
      redirect_to @virtualtest
    end
  end

  # Vérifie qu'on ne supprime pas un test en ligne
  def delete_online
    redirect_to root_path if @virtualtest.online
  end

  # Vérifie que l'on a assez de points si on est étudiant
  def enough_points
    if !current_user.sk.admin?
      score = current_user.sk.rating
      redirect_to root_path if score < 200
    end
  end
end

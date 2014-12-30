#encoding: utf-8
class VirtualtestsController < ApplicationController
  before_filter :signed_in_user
  before_filter :admin_user, only: [:destroy, :update, :edit, :new, :create, :put_online, :destroy]
  before_filter :recup, only: [:show, :destroy]
  before_filter :recup2, only: [:begin_test]
  before_filter :has_access, only: [:show, :begin_test]
  before_filter :online_test, only: [:show, :begin_test]
  before_filter :can_begin, only: [:begin_test]
  before_filter :can_be_online, only: [:put_online]

  def index
  end
  
  def show
  end

  def new
    @virtualtest = Virtualtest.new
  end

  def edit
  end

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

  def update
  end

  def destroy
    @virtualtest.problems.each do |p|
      p.virtualtest_id = 0
      p.position = 0
      p.save
    end
    @virtualtest.destroy
    redirect_to virtualtests_path
  end

  def put_online
    @virtualtest.online = true
    @virtualtest.save
    redirect_to @virtualtest
  end
  
  def begin_test
    t = Takentest.new
    t.user = current_user.sk
    t.virtualtest = @virtualtest
    t.status = 0
    t.takentime = DateTime.now
    t.save
    redirect_to @virtualtest
  end

  private

  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end
  
  def recup
    @virtualtest = Virtualtest.find(params[:id])
  end
  
  def recup2
    @virtualtest = Virtualtest.find(params[:virtualtest_id])
  end
  
  def has_access
    if !current_user.sk.admin?
      visible = true
      @virtualtest.problems.each do |p|
        p.chapters.each do |c|
          visible = false if !current_user.sk.solved?(c)
        end
      end
      redirect_to root_path if !visible
    end
  end
  
  def online_test
    redirect_to root_path if !@virtualtest.online && !current_user.sk.admin
  end
  
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
  
  def can_begin
    if current_user.sk.status(@virtualtest) >= 0
      redirect_to @virtualtest
    elsif Takentest.where(user_id: current_user.sk.id, status: 0).count > 0
      flash[:danger] = "Vous avez déjà un test virtuel en cours!"
      redirect_to @virtualtest
    end
  end
end

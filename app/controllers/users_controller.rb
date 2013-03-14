#encoding: utf-8
class UsersController < ApplicationController
  before_filter :signed_in_user,
    only: [:destroy, :index, :edit, :update, :show, :create_administrator]
  before_filter :correct_user,
    only: [:edit, :update]
  before_filter :admin_user,
    only: [:destroy, :create_administrator]
  before_filter :signed_out_user,
    only: [:new, :create]
  before_filter :destroy_admin,
    only: [:destroy]

  def index
    @users = User.paginate(page: params[:page])
  end
  def create
    @user = User.new(params[:user])
  	if @user.save
      sign_in @user
  	  flash[:success] = "Bienvenue sur OMB training!"
  	  redirect_to @user
  	else
  	  render 'new'
  	end
  end
  def show
    @user = User.find(params[:id])
  end
  def new
  	@user = User.new
  end
  def edit
  end
  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Profil mis à jour."
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end
  def destroy
    @user.destroy
    flash[:success] = "Utilisateur supprimé."
    redirect_to users_path
  end
  
  def create_administrator
    @user = User.find(params[:user_id])
    if @user.admin?
      flash[:error] = "I see what you did here! Mais non ;-)"
    else
      @user.toggle!(:admin)
      flash[:success] = "Utilisateur promu au rang d'administrateur!"
    end
    redirect_to users_path
  end

  private

  def signed_out_user
    if signed_in?
      redirect_to root_path
    end
  end
  def correct_user
    @user = User.find(params[:id])
    redirect_to root_path unless current_user?(@user)
  end
  def admin_user
    redirect_to root_path unless current_user.admin?
  end
  def destroy_admin
    @user = User.find(params[:id])
    if @user.admin?
      flash[:error] = "One does not simply destroy an admin."
      redirect_to root_path
    end
  end
end

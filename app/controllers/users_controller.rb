class UsersController < ApplicationController
  before_filter :signed_in_user,
    only: [:destroy, :index, :edit, :update]
  before_filter :correct_user,
    only: [:edit, :update]
  before_filter :admin_user,
    only: [:destroy]
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
  	  flash[:success] = "Welcome to the OMB training!"
  	  redirect_to @user
  	else
  	  render 'new'
  	end
  end
  def show
    @user = User.find(params[:id])
    @microposts = @user.microposts.paginate(page: params[:page])
  end
  def new
  	@user = User.new
  end
  def edit
  end
  def update
    if @user.update_attributes(params[:user])
      flash[:success] = "Profile updated."
      sign_in @user
      redirect_to @user
    else
      render 'edit'
    end
  end
  def destroy
    @user.destroy
    flash[:success] = "User destroyed."
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

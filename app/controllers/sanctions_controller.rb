#encoding: utf-8
class SanctionsController < ApplicationController
  before_action :signed_in_user, only: [:index, :new, :edit]
  before_action :signed_in_user_danger, only: [:create, :update, :destroy]
  before_action :root_user, only: [:index, :new, :edit, :create, :update, :destroy]
  
  before_action :get_sanction, only: [:edit, :update, :destroy]
  before_action :get_user, only: [:index, :new, :create]
  
  # Show sanctions (and history) of user
  def index
  end

  # Create a sanction (show the form)
  def new
    @sanction = Sanction.new(:user => @user, :sanction_type => :ban, :start_time => DateTime.now, :duration => 14)
  end

  # Update a sanction (show the form)
  def edit
  end
  
  # Create a sanction (send the form)
  def create
    @sanction = Sanction.new(params.require(:sanction).permit(:sanction_type, :start_time, :duration, :reason))
    @sanction.user = @user
    if @sanction.save
      flash[:success] = "Sanction ajoutée."
      redirect_to user_sanctions_path(@user)
    else
      render 'new'
    end
  end

  # Update a sanction (send the form)
  def update
    if @sanction.update(params.require(:sanction).permit(:sanction_type, :start_time, :duration, :reason))
      flash[:success] = "Sanction modifiée."
      redirect_to user_sanctions_path(@sanction.user)
    else
      render 'edit'
    end
  end

  # Delete a sanction
  def destroy
    user = @sanction.user
    @sanction.destroy
    flash[:success] = "Sanction supprimée."
    redirect_to user_sanctions_path(user)
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the sanction
  def get_sanction
    @sanction = Sanction.find_by_id(params[:id])
    return if check_nil_object(@sanction)
  end
  
  # Get the user
  def get_user
    @user = User.find_by_id(params[:user_id])
    return if check_nil_object(@user)
  end
end

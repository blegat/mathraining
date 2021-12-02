#encoding: utf-8
class ContestorganizationsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :destroy]
  before_action :admin_user, only: [:create, :destroy]
  
  before_action :get_contestorganization, only: [:destroy]

  # Add an organizer to a contest
  def create
    contestorganization = Contestorganization.create(params.require(:contestorganization).permit(:contest_id, :user_id))
    redirect_to contest_path(contestorganization.contest)
  end

  # Delete an organizer of a contest
  def destroy
    contest = @contestorganization.contest
    @contestorganization.destroy
    redirect_to contest_path(contest)
  end

  private
  
  ########## GET METHODS ##########

  # Get an organizer of a contest
  def get_contestorganization
    @contestorganization = Contestorganization.find_by_id(params[:id])
    return if check_nil_object(@contestorganization)
  end
end

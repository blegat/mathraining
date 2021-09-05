#encoding: utf-8
class ContestorganizationsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :destroy]
  before_action :admin_user, only: [:create, :destroy]
  before_action :get_contestorganization, only: [:destroy]

  # Ajouter un organisateur
  def create
    contestorganization = Contestorganization.new(params.require(:contestorganization).permit(:contest_id, :user_id))
    if !contestorganization.save
      flash[:success] = "Une erreur est survenue."
    end
    
    contest = Contest.find(params[:contestorganization][:contest_id])
    redirect_to contest
  end

  # Supprimer un organisateur
  def destroy
    contest = @contestorganization.contest
    @contestorganization.destroy
    redirect_to contest_path(contest)
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère
  def get_contestorganization
    @contestorganization = Contestorganization.find_by_id(params[:id])
    if @contestorganization.nil?
      render 'errors/access_refused' and return
    end
  end
end

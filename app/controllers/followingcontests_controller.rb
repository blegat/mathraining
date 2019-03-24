#encoding: utf-8
class FollowingcontestsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingcontest]
  before_action :signed_in_user_danger, only: [:add_followingcontest]
  before_action :get_contest, only: [:remove_followingcontest, :add_followingcontest]
  
  def add_followingcontest
    fol = Followingcontest.new
    fol.contest = @contest
    fol.user = current_user.sk
    fol.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail de rappel un jour avant la publication de chaque problème de ce concours."
    redirect_to @contest
  end

  def remove_followingcontest
    x = current_user.sk.followingcontests.where(:contest => @contest).first
    if !x.nil?
      x.destroy
    end
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce concours."
    redirect_to @contest
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  def get_contest
    @contest = Contest.find_by_id(params[:contest_id])
    if @contest.nil?
      render 'errors/access_refused' and return
    end
  end

end

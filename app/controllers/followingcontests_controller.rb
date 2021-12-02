#encoding: utf-8
class FollowingcontestsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingcontest]
  before_action :signed_in_user_danger, only: [:add_followingcontest]
  
  before_action :get_contest, only: [:remove_followingcontest, :add_followingcontest]
  
  # Create a followingcontest between current user and a contest
  def add_followingcontest
    current_user.sk.followed_contests << @contest unless current_user.sk.followed_contests.exists?(@contest.id)

    flash[:success] = "Vous recevrez dorénavant un e-mail de rappel un jour avant la publication de chaque problème de ce concours."
    redirect_to @contest
  end

  # Remove a followingcontest between current user and a contest
  def remove_followingcontest
    current_user.sk.followed_contests.destroy(@contest)
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce concours."
    redirect_to @contest
  end
  
  private
  
  ########## GET METHODS ##########
  
  # Get the contest
  def get_contest
    @contest = Contest.find_by_id(params[:contest_id])
    return if check_nil_object(@contest)
  end

end

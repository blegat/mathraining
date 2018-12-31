# -*- coding: utf-8 -*-

class FollowingcontestsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingcontest]
  before_action :signed_in_user_danger, only: [:add_followingcontest]
  
  def add_followingcontest
    con = Contest.find(params[:contest_id])
    fol = Followingcontest.new
    fol.contest = con
    fol.user = current_user.sk
    fol.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail de rappel un jour avant la publication de chaque problème de ce concours."
    redirect_back(fallback_location: contest_path(con))
  end

  def remove_followingcontest
    con = Contest.find(params[:contest_id])
    x = current_user.sk.followingcontests.where(:contest => con).first
    if !x.nil?
      x.destroy
    end
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce concours."
    redirect_back(fallback_location: contest_path(con))
  end

end

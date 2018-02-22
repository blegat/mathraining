# -*- coding: utf-8 -*-

class FollowingsubjectsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingsubject, :remove_followingmessage]
  before_action :signed_in_user_danger, only: [:add_followingsubject, :add_followingmessage]

  def add_followingsubject
    sub = Subject.find(params[:subject_id])
    fol = Followingsubject.new
    fol.subject = sub
    fol.user = current_user.sk
    fol.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque fois qu'un nouveau message sera posté sur ce sujet."
    redirect_back(fallback_location: subject_path(sub))
  end

  def remove_followingsubject
    sub = Subject.find(params[:subject_id])
    x = current_user.sk.followingsubjects.where(:subject => sub).first
    if !x.nil?
      x.destroy
    end
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce sujet."
    redirect_back(fallback_location: subject_path(sub))
  end

  def add_followingmessage
    current_user.sk.follow_message = true
    current_user.sk.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

  def remove_followingmessage
    current_user.sk.follow_message = false
    current_user.sk.save
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail lors d'un nouveau message privé."
    redirect_back(fallback_location: new_discussion_path)
  end

end

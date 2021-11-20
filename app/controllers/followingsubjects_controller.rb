# -*- coding: utf-8 -*-

class FollowingsubjectsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingsubject]
  before_action :signed_in_user_danger, only: [:add_followingsubject]
  before_action :get_subject, only: [:remove_followingsubject, :add_followingsubject]

  def add_followingsubject
    fol = Followingsubject.new
    fol.subject = @subject
    fol.user = current_user.sk
    fol.save
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque fois qu'un nouveau message sera posté sur ce sujet."
    redirect_back(fallback_location: subject_path(@subject))
  end

  def remove_followingsubject
    x = current_user.sk.followingsubjects.where(:subject => @subject).first
    if !x.nil?
      x.destroy
    end
    
    flash[:success] = "Vous ne recevrez maintenant plus d'e-mail concernant ce sujet."
    redirect_back(fallback_location: subject_path(@subject))
  end
  
  ########## PARTIE PRIVEE ##########
  private
  
  def get_subject
    @subject = Subject.find_by_id(params[:subject_id])
    return if check_nil_object(@subject)
  end

end

# -*- coding: utf-8 -*-

class FollowingsubjectsController < ApplicationController
  before_action :signed_in_user, only: [:remove_followingsubject]
  before_action :signed_in_user_danger, only: [:add_followingsubject]
  before_action :get_subject, only: [:remove_followingsubject, :add_followingsubject]

  def add_followingsubject
    current_user.sk.followed_subjects << @subject unless current_user.sk.followed_subjects.exists?(@subject.id)
    
    flash[:success] = "Vous recevrez dorénavant un e-mail à chaque fois qu'un nouveau message sera posté sur ce sujet."
    redirect_back(fallback_location: subject_path(@subject))
  end

  def remove_followingsubject
    current_user.sk.followed_subjects.destroy(@subject)
    
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

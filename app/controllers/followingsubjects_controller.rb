# -*- coding: utf-8 -*-
class FollowingsubjectsController < ApplicationController
  before_filter :signed_in_user

  def add_followingsubject
    sub = Subject.find_by_id(params[:subject_id])
    fol = Followingsubject.new
    fol.subject = sub
    fol.user = current_user.sk
    if fol.save
      flash[:success] = "Vous suivez maintenant ce sujet."
    else
      flash[:danger] = "Une erreur est survenue."
    end

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to subject_path(sub)
    end
  end

  def remove_followingsubject
    sub = Subject.find_by_id(params[:subject_id])
    if current_user.sk.followed_subjects.exists?(sub)
      current_user.sk.followed_subjects.delete(sub)
      flash[:success] = "Vous ne suivez plus ce sujet."
    else
      flash[:danger] = "Vous ne suiviez déjà pas ce sujet."
    end

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to subject_path(sub)
    end
  end
  
end

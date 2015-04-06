# -*- coding: utf-8 -*-

class FollowingsubjectsController < ApplicationController
  before_filter :signed_in_user

  def add_followingsubject
    sub = Subject.find_by_id(params[:subject_id])
    fol = Followingsubject.new
    fol.subject = sub
    fol.user = current_user.sk
    fol.save

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to subject_path(sub)
    end
  end

  def remove_followingsubject
    sub = Subject.find_by_id(params[:subject_id])
    x = current_user.sk.followingsubjects.where(:subject => sub).first
    if !x.nil?
      x.destroy
    end

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to subject_path(sub)
    end
  end

end

# -*- coding: utf-8 -*-

class FollowingsubjectsController < ApplicationController
  before_action :signed_in_user

  def add_followingsubject
    sub = Subject.find(params[:subject_id])
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
    sub = Subject.find(params[:subject_id])
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

  def add_followingmessage
    current_user.sk.follow_message = true
    current_user.sk.save

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to new_discussion_path
    end
  end

  def remove_followingmessage
    current_user.sk.follow_message = false
    current_user.sk.save

    if request.env["HTTP_REFERER"]
      redirect_to(:back)
    else
      redirect_to new_discussion_path
    end
  end

end

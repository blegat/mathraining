#encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  include SessionsHelper
  include ApplicationHelper

  before_filter :active_user
  before_filter :check_up

  ########## PARTIE PRIVEE ##########
  private

  # Vérifie que l'utilisateur n'a pas eu son compte désactivé.
  def active_user
    if signed_in? && !current_user.active
      flash[:danger] = "Ce compte a été désactivé et n'est plus accessible."
      sign_out
      redirect_to root_path
    end
  end

  # Regarde s'il y a un test virtuel qui vient de se terminer
  def check_up
    maintenant = DateTime.now.to_i
    Takentest.where(status: 0).each do |t|
      debut = t.takentime.to_i
      if debut + t.virtualtest.duration*60 < maintenant
        t.status = 1
        t.save
        u = t.user
        v = t.virtualtest
        v.problems.each do |p|
          p.submissions.where(user_id: u.id, intest: true).each do |s|
            s.visible = true
            s.save
          end
        end
      end
    end
  end

  # Vérifie qu'il ne s'agit pas d'un administrateur dans la peau de quelqu'un
  def notskin_user
    if current_user.other
      flash[:danger] = "Vous ne pouvez pas effectuer cette action dans la peau de quelqu'un."
      redirect_to(:back)
    end
  end

  # Vérifie qu'on est administrateur
  def admin_user
    redirect_to root_path unless current_user.sk.admin?
  end

  # Vérifie que l'on est root
  def root_user
    redirect_to root_path unless current_user.sk.root
  end

  def point_attribution(user)
    user.rating = 0
    partials = user.pointspersections
    partial = Array.new

    Section.all.each do |s|
      partial[s.id] = partials.where(:section_id => s.id).first
      if partial[s.id].nil?
        newpoint = Pointspersection.new
        newpoint.points = 0
        newpoint.section_id = s.id
        user.pointspersections << newpoint
        partial[s.id] = user.pointspersections.where(:section_id => s.id).first
      end
      partial[s.id].points = 0
    end

    user.solvedexercises.each do |e|
      if e.correct
        exo = e.exercise
        pt = exo.value

        if !exo.chapter.section.fondation? # Pas un fondement
          user.rating = user.rating + pt
        end

        partial[exo.chapter.section.id].points = partial[exo.chapter.section.id].points + pt
      end
    end

    user.solvedqcms.each do |q|
      if q.correct
        qcm = q.qcm
        pt = qcm.value

        if !qcm.chapter.section.fondation? # Pas un fondement
          user.rating = user.rating + pt
        end

        partial[qcm.chapter.section.id].points = partial[qcm.chapter.section.id].points + pt
      end
    end

    user.solvedproblems.each do |p|
      problem = p.problem
      pt = problem.value

      user.rating = user.rating + pt;

      partial[problem.section.id].points = partial[problem.section.id].points + pt
    end

    user.save
    Section.all.each do |s|
      partial[s.id].save
    end
  end
end

#encoding: utf-8
class SolvedqcmsController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update]
  before_action :before_all
  before_action :online_chapter
  before_action :unlocked_chapter

  # On tente de résoudre un qcm (pour la première fois)
  def create
    qcm = @qcm2
    user = current_user.sk

    previous = Solvedqcm.where(:qcm_id => qcm, :user_id => current_user.sk).count
    if previous > 0
      redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
    end

    link = Solvedqcm.new
    link.user_id = user.id
    link.qcm_id = qcm.id
    link.nb_guess = 1
    link.resolutiontime = DateTime.now

    good_guess = true

    if qcm.many_answers
      if params[:ans]
        answer = params[:ans]
      else
        answer = {}
      end

      qcm.choices.each do |c|
        if answer[c.id.to_s]
          # Répondu vrai
          if !c.ok
            good_guess = false
          end
        else
          # Répondu faux
          if c.ok
            good_guess = false
          end
        end
      end

      if good_guess
        # Correct
        link.correct = true
        link.save
      else
        # Incorrect
        link.correct = false
        link.save

        qcm.choices.each do |c|
          if answer[c.id.to_s]
            link.choices << c
          end
        end
      end
    else
      if !params[:ans]
        flash[:danger] = "Veuillez cocher une réponse."
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end

      rep = qcm.choices.where(:ok => true).first
      if rep.id == params[:ans].to_i
        link.correct = true
        link.save
      else
        link.correct = false
        link.save
        choice = Choice.find(params[:ans])
        link.choices << choice
      end
    end
    
    qcm.nb_tries = qcm.nb_tries+1
    if link.correct
      qcm.nb_firstguess = qcm.nb_firstguess+1
      point_attribution(current_user.sk, qcm)
    end
    qcm.save

    redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id)
  end

  # On tente de résoudre un qcm une nouvelle fois
  def update
    qcm = @qcm2
    user = current_user.sk
    link = Solvedqcm.where(:user_id => user, :qcm_id => qcm).first

    if link.correct
      redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
    end

    link.nb_guess = link.nb_guess + 1
    link.resolutiontime = DateTime.now

    good_guess = true
    autre = false

    if qcm.many_answers

      if params[:ans]
        answer = params[:ans]
      else
        answer = {}
      end

      qcm.choices.each do |c|
        if answer[c.id.to_s]
          # Répondu vrai
          if !c.ok
            good_guess = false
          end
          if !link.choices.exists?(c)
            autre = true
          end
        else
          # Répondu faux
          if c.ok
            good_guess = false
          end
          if link.choices.exists?(c)
            autre = true
          end
        end
      end

      # Il s'agit de la même réponse que la précédente : on ne la compte pas
      if !autre
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end

      if good_guess
        # Correct
        link.correct = true
        link.save
        link.choices.clear
      else
        # Incorrect
        link.correct = false
        link.save
        link.choices.clear
        qcm.choices.each do |c|
          if answer[c.id.to_s]
            link.choices << c
          end
        end
      end

    else
      if !params[:ans]
        flash[:danger] = "Veuillez cocher une réponse."
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end

      rep = qcm.choices.where(:ok => true).first
      if params[:ans].to_i == link.choices.first.id
        redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
      end

      if rep.id == params[:ans].to_i
        link.correct = true
        link.save
        link.choices.clear
      else
        link.correct = false
        link.save
        choice = Choice.find(params[:ans])
        link.choices.clear
        link.choices << choice
      end
    end

    if link.correct
      point_attribution(current_user.sk, qcm)
    end

    redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id)
  end

  ########## PARTIE PRIVEE ##########
  private

  # On récupère le qcm et le chapitre
  def before_all
    @qcm2 = Qcm.find(params[:qcm_id])
    @chapter = @qcm2.chapter
  end

  # Il faut que le chapitre soit en ligne
  def online_chapter
    redirect_to root_path unless (current_user.sk.admin? || @chapter.online)
  end

  # Il faut qu'on puisse faire les exercices
  def unlocked_chapter
    if !current_user.sk.admin?
      @chapter.prerequisites.each do |p|
        if (!p.section.fondation && !current_user.sk.chapters.exists?(p))
          redirect_to root_path and return
        end
      end
    end
  end

  # Attribution des points pour un qcm
  def point_attribution(user, qcm)
    pt = qcm.value

    partials = user.pointspersections

    if !qcm.chapter.section.fondation # Pas un fondement
      user.rating = user.rating + pt
      user.save
    end

    partial = partials.where(:section_id => qcm.chapter.section.id).first
    partial.points = partial.points + pt
    partial.save
  end

end

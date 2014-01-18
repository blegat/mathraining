#encoding: utf-8
class SolvedqcmsController < ApplicationController
  before_filter :signed_in_user
  before_filter :before_all
  before_filter :online_chapter
  before_filter :unlocked_chapter

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
        flash[:error] = "Veuillez cocher une réponse."
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

    if link.correct
      point_attribution(current_user.sk, qcm)
    end

    redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id)
  end

  def update
    qcm = @qcm2
    user = current_user.sk
    link = Solvedqcm.where(:user_id => user, :qcm_id => qcm).first

    if link.correct
      redirect_to chapter_path(qcm.chapter, :type => 3, :which => qcm.id) and return
    end

    link.nb_guess = link.nb_guess + 1

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
        flash[:error] = "Veuillez cocher une réponse."
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


  def before_all
    @qcm2 = Qcm.find(params[:qcm_id])
    @chapter = @qcm2.chapter
  end

  def online_chapter
    redirect_to sections_path unless (current_user.sk.admin? || @chapter.online)
  end

  def unlocked_chapter
    if !current_user.sk.admin?
      @chapter.prerequisites.each do |p|
        if (p.sections.count > 0 && !current_user.sk.chapters.exists?(p))
          redirect_to sections_path and return
        end
      end
    end
  end

  def point_attribution(user, qcm)
    poss = qcm.choices.count
    if qcm.many_answers
      pt = 2*(poss-1)
    else
      pt = poss
    end

    partials = user.pointspersections

    if !qcm.chapter.sections.empty? # Pas un fondement
      user.point.rating = user.point.rating + pt
      user.point.save
    else # Fondement
      partial = partials.where(:section_id => 0).first
      partial.points = partial.points + pt
      partial.save
    end

    qcm.chapter.sections.each do |s| # Section s
      partial = partials.where(:section_id => s.id).first
      partial.points = partial.points + pt
      partial.save
    end
  end

end

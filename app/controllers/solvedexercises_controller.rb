#encoding: utf-8
class SolvedexercisesController < ApplicationController
  before_filter :signed_in_user
  before_filter :before_create, only: [:create]
  before_filter :before_update, only: [:update]
  before_filter :online_chapter
  before_filter :unlocked_chapter


  def create
    exercise = @exercise2
    user = current_user.sk

    previous = Solvedexercise.where(:exercise_id => @exercise2, :user_id => current_user.sk).count
    if previous > 0
      redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id) and return
    end

    link = Solvedexercise.new
    link.user_id = user.id
    link.exercise_id = exercise.id
    link.guess = params[:solvedexercise][:guess].gsub(",",".").to_f
    link.nb_guess = 1
    if exercise.decimal
      if absolu(exercise.answer, link.guess) < 0.001
        link.correct = true
        link.save
      else
        link.correct = false
        link.save
      end
    else
      if exercise.answer.to_i == link.guess.to_i
        link.correct = true
        link.save
      else
        link.correct = false
        link.save
      end
    end

    if link.correct
      point_attribution(current_user.sk, exercise)
    end

    redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id)
  end

  def update
    exercise = @exercise2
    link = @link2
    user = link.user

    if link.correct
      redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id) and return
    end

    if link.guess != params[:solvedexercise][:guess].gsub(",",".").to_f
      link.nb_guess = link.nb_guess + 1
      link.guess = params[:solvedexercise][:guess].gsub(",",".").to_f

      if exercise.decimal
        if absolu(exercise.answer, link.guess) < 0.001
          link.correct = true
          link.save
        else
          link.correct = false
          link.save
        end
      else
        if exercise.answer.to_i == link.guess.to_i
          link.correct = true
          link.save
        else
          link.correct = false
          link.save
        end
      end
      link.save
    end

    if link.correct
      point_attribution(current_user.sk, exercise)
    end

    redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id)
  end

  private

  def absolu(a, b)
    if a > b
      return a-b
    else
      return b-a
    end
  end

  def before_create
    @exercise2 = Exercise.find(params[:solvedexercise][:exercise_id])
    @chapter = @exercise2.chapter
  end

  def before_update
    @link2 = Solvedexercise.find(params[:id])
    @exercise2 = @link2.exercise
    @chapter = @exercise2.chapter
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

  def point_attribution(user, exo)
    if exo.decimal
      pt = 10
    else
      pt = 6
    end

    partials = user.pointspersections

    if !exo.chapter.section.fondation # Pas un fondement
      user.point.rating = user.point.rating + pt
      user.point.save
    end

    partial = partials.where(:section_id => exo.chapter.section.id).first
    partial.points = partial.points + pt
    partial.save
  end

end

#encoding: utf-8
class SolvedexercisesController < ApplicationController
  before_action :signed_in_user_danger, only: [:create, :update]
  before_action :before_create, only: [:create]
  before_action :before_update, only: [:update]
  before_action :online_chapter
  before_action :unlocked_chapter

  # On tente de résoudre un exercice
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
    link.resolutiontime = DateTime.now
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

    exercise.nb_tries = exercise.nb_tries+1
    if link.correct
      exercise.nb_firstguess = exercise.nb_firstguess+1
      point_attribution(current_user.sk, exercise)
    end
    exercise.save
    
    # On augmente chapter.nb_tries si c'est le premier exercice essayé
    already = false
    chapter = exercise.chapter
    chapter.exercises.each do |e|
      already = true if(e != exercise && Solvedexercise.where(:user_id => current_user.sk.id, :exercise_id => e.id).count > 0)
    end
    chapter.qcms.each do |q|
      already = true if(Solvedqcm.where(:user_id => current_user.sk.id, :qcm_id => q.id).count > 0)
    end
    
    unless already
      chapter.nb_tries = chapter.nb_tries+1
      chapter.save
    end

    redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id)
  end

  # On tente de résoudre un exercice une nouvelle fois
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
      link.resolutiontime = DateTime.now

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

  ########## PARTIE PRIVEE ##########
  private

  # Retourne la différence (en valeur absolue) entre a et b
  def absolu(a, b)
    if a > b
      return a-b
    else
      return b-a
    end
  end

  # On récupère l'exercice et le chapitre
  def before_create
    @exercise2 = Exercise.find(params[:solvedexercise][:exercise_id])
    @chapter = @exercise2.chapter
  end

  def before_update
    @link2 = Solvedexercise.find(params[:id])
    @exercise2 = @link2.exercise
    @chapter = @exercise2.chapter
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

  # Attribution des points pour un exercice
  def point_attribution(user, exo)
    pt = exo.value

    partials = user.pointspersections

    if !exo.chapter.section.fondation # Pas un fondement
      user.rating = user.rating + pt
      user.save
    end

    partial = partials.where(:section_id => exo.chapter.section.id).first
    partial.points = partial.points + pt
    partial.save
  end

end

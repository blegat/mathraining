class SolvedexercisesController < ApplicationController
  before_filter :signed_in_user
  
  def create
    exercise = Exercise.find(params[:solvedexercise][:exercise_id])
    user = current_user
    link = Solvedexercise.new
    link.user_id = user.id
    link.exercise_id = exercise.id
    link.guess = params[:solvedexercise][:guess].gsub(",",".").to_f
    link.nb_guess = 1
    if exercise.decimal
      if absolu(exercise.answer, link.guess) < 0.001
        link.correct = true
      else
        link.correct = false
      end
    else
      if exercise.answer.to_i == link.guess.to_i
        link.correct = true
      else
        link.correct = false
      end
    end
    link.save
    redirect_to chapter_path(exercise.chapter, :type => 2, :which => exercise.id)
  end
  
  def update
    link = Solvedexercise.find(params[:id])
    exercise = link.exercise
    user = link.user
    if link.guess != params[:solvedexercise][:guess].gsub(",",".").to_f
      link.nb_guess = link.nb_guess + 1
      link.guess = params[:solvedexercise][:guess].gsub(",",".").to_f
      
      if exercise.decimal
        if absolu(exercise.answer, link.guess) < 0.001
          link.correct = true
        else
          link.correct = false
        end
      else
        if exercise.answer.to_i == link.guess.to_i
          link.correct = true
        else
          link.correct = false
        end
      end
      link.save
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
  
end

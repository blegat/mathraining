class Solvedexercise < ActiveRecord::Base
  attr_accessible :correct, :exercise_id, :guess, :nb_guess, :user_id
  
  belongs_to :exercise
  belongs_to :user
  
end

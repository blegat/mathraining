#encoding: utf-8

# == Schema Information
#
# Table name: globalstatistics
#
#  id                 :bigint           not null, primary key
#  nb_ranked_users    :integer          default(0)
#  nb_solvedproblems  :integer          default(0)
#  nb_solvedquestions :integer          default(0)
#  nb_points          :integer          default(0)
#
class Globalstatistic < ActiveRecord::Base

  # VALIDATIONS

  validates :nb_ranked_users, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_solvedproblems, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_solvedquestions, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :nb_points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  
  # OTHER METHODS
  
  # Get the only one row of this table
  def self.get
    statistic = Globalstatistic.first
    if statistic.nil?
      statistic = Globalstatistic.create
      statistic.update_all
    end
    return statistic
  end
  
  # Recompute all statistics from scratch
  def update_all
    self.nb_ranked_users = User.where(:role => :student).where("rating > 0").count
    self.nb_solvedproblems = Solvedproblem.count
    self.nb_solvedquestions = Solvedquestion.count
    self.nb_points = User.where(:role => :student).sum(:rating)
    self.save
  end
  
  # Update statistics after a user solved a question
  def update_after_question_solved(old_user_points, value)
    self.nb_ranked_users += 1 if old_user_points == 0
    self.nb_solvedquestions += 1
    self.nb_points += value
    self.save
  end
  
  # Update statistics after a user solved a problem
  def update_after_problem_solved(value)
    self.nb_solvedproblems += 1
    self.nb_points += value
    self.save
  end
  
  # Update statistics after a problem is unsolved (submission marked as incorrect)
  def update_after_problem_unsolved(value)
    self.nb_solvedproblems -= 1
    self.nb_points -= value
    self.save
  end
end

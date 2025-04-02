#encoding: utf-8

# == Schema Information
#
# Table name: contestscores
#
#  id         :integer          not null, primary key
#  contest_id :integer
#  user_id    :integer
#  rank       :integer
#  score      :integer
#  medal      :integer
#
include ApplicationHelper

class Contestscore < ActiveRecord::Base

  enum medal: {:undefined_medal    => -1, # contest not yet finished or without medals
               :no_medal           =>  0,
               :honourable_mention =>  1,
               :bronze_medal       =>  2,
               :silver_medal       =>  3,
               :gold_medal         =>  4}

  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  belongs_to :user

  # VALIDATIONS

  validates :contest_id, uniqueness: { scope: :user_id }
  validates :rank, presence: true, numericality: { greater_than: 0 }
  validates :score, presence: true, numericality: { greater_than: 0 }
  validates :medal, presence: true

end

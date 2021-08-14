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
  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  belongs_to :user

  # VALIDATIONS

  validates :score, presence: true, numericality: { greater_than: 0 }
  validates :medal, presence: true

end

#encoding: utf-8
# == Schema Information
#
# Table name: contestscores
#
#  id          :integer          not null, primary key
#  contest_id  :reference
#  user_id     :reference
#  score       :integer
#  medal       :integer
#
#  medal = -1 ==> not applicable (contest not yet finished or without medals)
#  medal =  0 ==> no medal
#  medal =  1 ==> honourable mention
#  medal =  2 ==> bronze medal
#  medal =  3 ==> silver medal
#  medal =  4 ==> gold medal
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

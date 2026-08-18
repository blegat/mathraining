#encoding: utf-8

# == Schema Information
#
# Table name: externalsolutions
#
#  id         :bigint           not null, primary key
#  url        :text
#  problem_id :bigint
#
# Indexes
#
#  index_externalsolutions_on_problem_id  (problem_id)
#
include ApplicationHelper

class Externalsolution < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :problem
  has_many :extracts, dependent: :destroy

  # VALIDATIONS

  validates :url, presence: true, length: { maximum: 1000 }
  
end

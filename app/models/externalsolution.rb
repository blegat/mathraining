#encoding: utf-8

# == Schema Information
#
# Table name: externalsolutions
#
#  id         :bigint           not null, primary key
#  problem_id :bigint
#  url        :text
#
include ApplicationHelper

class Externalsolution < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :problem
  has_many :extracts, dependent: :destroy

  # VALIDATIONS

  validates :url, presence: true, length: { maximum: 1000 }
  
end

#encoding: utf-8

# == Schema Information
#
# Table name: externalsolutions
#
#  id         :integer          not null, primary key
#  problem_id :integer
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

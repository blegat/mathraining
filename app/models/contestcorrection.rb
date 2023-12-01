#encoding: utf-8

# == Schema Information
#
# Table name: contestcorrections
#
#  id                 :integer          not null, primary key
#  contestsolution_id :integer
#  content            :text
#
include ApplicationHelper

class Contestcorrection < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :contestsolution
  
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates_uniqueness_of :contestsolution_id
  validates :content, presence: true, length: { maximum: 16000 }  # Limited to 8000 in the form but end-of-lines count twice

end

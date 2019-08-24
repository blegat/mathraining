#encoding: utf-8
# == Schema Information
#
# Table name: contestcorrections
#
#  id                 :integer          not null, primary key
#  contestsolution_id :reference
#  content            :text
#  status             :integer
#

include ApplicationHelper

class Contestcorrection < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :contestsolution
  
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 }  # Limited to 8000 in the form but end-of-lines count twice

end

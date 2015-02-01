#encoding: utf-8
# == Schema Information
#
# Table name: solvedqcms
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  qcm_id         :integer
#  correct        :boolean
#  nb_guess       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  resolutiontime :datetime
#

class Solvedqcm < ActiveRecord::Base
  attr_accessible :correct, :qcm_id, :nb_guess, :user_id, :resolutiontime

  # BELONGS_TO, HAS_MANY
  
  belongs_to :qcm
  belongs_to :user
  has_and_belongs_to_many :choices
  
  # VALIDATIONS
  
  validates :qcm_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true
  validates :nb_guess, presence: true, numericality: { greater_than_or_equal_to: 1 }
end

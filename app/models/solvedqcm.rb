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

  belongs_to :qcm
  belongs_to :user
  has_and_belongs_to_many :choices

end

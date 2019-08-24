#encoding: utf-8
# == Schema Information
#
# Table name: contestsolutions
#
#  id                 :integer          not null, primary key
#  user_id            :reference
#  contestproblem_id  :reference
#  content            :text
#  official           :boolean
#  correct            :boolean
#

include ApplicationHelper

class Contestsolution < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :contestproblem
  belongs_to :user
  has_one :contestcorrection, dependent: :destroy
  
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :score, presence: true, inclusion: { in: [-1, 0, 1, 2, 3, 4, 5, 6, 7] }
  
  # Rend l'icone correspondante
  def icon
    if !corrected
      'tiret.gif'
    else
      if star
        'star1.png'
      elsif score == 7
        'V.gif'
      else
        'X.gif'
      end
    end
  end

end

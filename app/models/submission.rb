#encoding: utf-8
# == Schema Information
#
# Table name: submissions
#
#  id         :integer          not null, primary key
#  problem_id :integer
#  user_id    :integer
#  content    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :integer
#  intest     :boolean
#  visible    :boolean
#  score      :integer
#

class Submission < ActiveRecord::Base
  attr_accessible :content, :status, :lastcomment, :intest, :visible, :score, :star

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  has_many :corrections, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, source: :user
  has_many :notifs, dependent: :destroy
  has_many :submissionfiles, dependent: :destroy
  has_many :fakesubmissionfiles, dependent: :destroy

  # VALIDATIONS

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 8000 }
  validates :status, presence: true, inclusion: { in: [-1, 0, 1, 2, 3] }
  # -1 : brouillon
  # 0: pas corrigé
  # 1: [corrigé et répondu et]* corrigé ou lu
  # 2: résolu
  # 3: erroné + commentaire d'un étudiant jamais lu

  # Rend true si la soumission est correcte
  def correct?
    status == 2
  end

  # Rend l'icone correspondante
  def icon
    if star
      'star1.png'
    else
      case status
      when -1
        'tiret.gif'
      when 0
        'tiret.gif'
      when 1, 3
        'X.gif'
      when 2
        'V.gif'
      end
    end
  end
end

#encoding: utf-8

# == Schema Information
#
# Table name: submissions
#
#  id          :integer          not null, primary key
#  problem_id  :integer
#  user_id     :integer
#  content     :text
#  created_at  :datetime
#  updated_at  :datetime
#  status      :integer          default(0)
#  intest      :boolean          default(FALSE)
#  visible     :boolean          default(TRUE)
#  score       :integer          default(-1)
#  lastcomment :datetime
#  star        :boolean          default(FALSE)
#
class Submission < ActiveRecord::Base
  # attr_accessible :content, :status, :lastcomment, :intest, :visible, :score, :star

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :problem
  has_many :corrections, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, source: :user
  has_many :notifs, dependent: :destroy
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :status, presence: true, inclusion: { in: [-1, 0, 1, 2, 3, 4] }
  # -1 : brouillon
  # 0: pas corrigé
  # 1: erroné (lu)
  # 2: résolu
  # 3: erroné + commentaire d'un étudiant jamais lu
  # 4: plagié (plus possible de soumettre sur ce problème ni de commenter)

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
      when 1, 3, 4
        'X.gif'
      when 2
        'V.gif'
      end
    end
  end
end

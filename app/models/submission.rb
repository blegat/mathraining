class Submission < ActiveRecord::Base
  attr_accessible :content, :status
  belongs_to :user
  belongs_to :problem

  has_many :corrections, dependent: :destroy
  has_many :followings, dependent: :destroy
  has_many :followers, through: :followings, source: :user
  has_many :notifs, dependent: :destroy
  has_many :submissionfiles, dependent: :destroy
  has_many :fakesubmissionfiles, dependent: :destroy

  validates :user_id, presence: true
  validates :problem_id, presence: true
  validates :content, presence: true, length: { maximum: 8000 }
  validates :status, presence: true, inclusion: { in: [0, 1, 2, 3] }
  # 0: pas corrigé
  # 1: [corrigé et répondu et]* corrigé
  # 2: résolu
  # 3: corrigé et répondu

  def correct?
    status == 2
  end
  def icon
    case status
    when 0
      '/assets/tiret.gif'
    when 1, 3
      '/assets/X.gif'
    when 2
      '/assets/V.gif'
    end

  end
end

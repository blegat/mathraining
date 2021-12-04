#encoding: utf-8

# == Schema Information
#
# Table name: submissions
#
#  id                :integer          not null, primary key
#  problem_id        :integer
#  user_id           :integer
#  content           :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  status            :integer          default(0)
#  intest            :boolean          default(FALSE)
#  visible           :boolean          default(TRUE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
class Submission < ActiveRecord::Base

  # status = -1 : draft
  #           0 : not corrected yet
  #           1 : wrong (last comment read)
  #           2 : correct
  #           3 : wrong + unread comment from the student
  #           4 : plagiarized (not possible to submit a new submission or to comment)

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
  
  # OTHER METHODS

  # Give the icon for the submission
  def icon
    if star
      'star1.png'
    else
      case status
      when -1, 0
        'tiret.gif'
      when 1, 3, 4
        'X.gif'
      when 2
        'V.gif'
      end
    end
  end
end

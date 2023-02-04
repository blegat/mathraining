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
#  status            :integer          default("waiting")
#  intest            :boolean          default(FALSE)
#  visible           :boolean          default(TRUE)
#  score             :integer          default(-1)
#  last_comment_time :datetime
#  star              :boolean          default(FALSE)
#
class Submission < ActiveRecord::Base
  
  enum status: {:draft         => -1, # draft (only for the student)
                :waiting       =>  0, # waiting for a correction
                :wrong         =>  1, # wrong (and last comment was marked as read)
                :correct       =>  2, # correct
                :wrong_to_read =>  3, # wrong, but last comment was not read yet
                :plagiarized   =>  4} # plagiarized

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
  
  # OTHER METHODS

  # Give the icon for the submission
  def icon
    if star
      return 'star1.png'
    else
      if draft? or waiting?
        return 'tiret.gif'
      elsif wrong? or wrong_to_read? or plagiarized?
        return 'X.gif'
      elsif correct?
        return 'V.gif'
      end
    end
  end
end

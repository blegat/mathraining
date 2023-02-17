#encoding: utf-8

# == Schema Information
#
# Table name: subjects
#
#  id                   :integer          not null, primary key
#  title                :string
#  content              :text
#  user_id              :integer
#  chapter_id           :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  last_comment_time    :datetime
#  for_correctors       :boolean          default(FALSE)
#  important            :boolean          default(FALSE)
#  section_id           :integer
#  for_wepion           :boolean          default(FALSE)
#  category_id          :integer
#  question_id          :integer
#  contest_id           :integer
#  problem_id           :integer
#  last_comment_user_id :integer
#  subject_type         :integer          default("normal")
#
class Subject < ActiveRecord::Base

  enum subject_type: {:normal           => 0, # all normal subjects
                      :corrector_alerts => 1} # subject with automatic alert about strange behaviors

  # BELONGS_TO, HAS_MANY

  has_many :messages, dependent: :destroy
  belongs_to :user, optional: true # For automatic messages
  belongs_to :chapter, optional: true
  belongs_to :section, optional: true
  belongs_to :category, optional: true
  belongs_to :question, optional: true
  belongs_to :contest, optional: true
  belongs_to :problem, optional: true
  belongs_to :last_comment_user, class_name: "User", optional: true # For automatic messages
  has_many :followingsubjects, dependent: :destroy
  has_many :following_users, through: :followingsubjects, source: :user
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :user_id, presence: true
  validates :last_comment_time, presence: true
  validates :last_comment_user_id, presence: true
  
  # OTHER METHODS
  
  # Tells if the subject can be seen by the given user
  def can_be_seen_by(user)
    if self.for_wepion && !user.admin? && !user.wepion?
      return false
    elsif self.for_correctors && !user.admin? && !user.corrector?
      return false
    else
      return true
    end
  end

end

#encoding: utf-8

# == Schema Information
#
# Table name: subjects
#
#  id                   :integer          not null, primary key
#  for_correctors       :boolean          default(FALSE)
#  for_wepion           :boolean          default(FALSE)
#  important            :boolean          default(FALSE)
#  last_comment_time    :datetime
#  subject_type         :integer          default("normal")
#  title                :string
#  category_id          :integer
#  chapter_id           :integer
#  contest_id           :integer
#  last_comment_user_id :integer
#  problem_id           :integer
#  question_id          :integer
#  section_id           :integer
#
# Indexes
#
#  index_subjects_on_chapter_id                       (chapter_id)
#  index_subjects_on_contest_id                       (contest_id) UNIQUE
#  index_subjects_on_important_and_last_comment_time  (important,last_comment_time)
#  index_subjects_on_last_comment_time                (last_comment_time)
#  index_subjects_on_problem_id                       (problem_id) UNIQUE
#  index_subjects_on_question_id                      (question_id) UNIQUE
#

class NoWepionCorrectorValidator < ActiveModel::Validator
  def validate(record)
    if record.for_wepion? && record.for_correctors?
      record.errors.add(:base, "Un sujet ne peut pas être destiné à la fois aux correcteurs et aux étudiants de Wépion.")
    end
  end
end

class Subject < ActiveRecord::Base

  enum :subject_type, {:normal           => 0, # all normal subjects
                       :corrector_alerts => 1} # subject with automatic alert about strange behaviors

  # BELONGS_TO, HAS_MANY

  has_many :messages, dependent: :destroy
  belongs_to :chapter, optional: true
  belongs_to :section, optional: true
  belongs_to :category, optional: true
  belongs_to :question, optional: true
  belongs_to :problem, optional: true
  belongs_to :contest, optional: true
  belongs_to :last_comment_user, class_name: "User", optional: true # For automatic messages
  has_and_belongs_to_many :following_users, -> { distinct }, class_name: "User", join_table: :followingsubjects

  # BEFORE, AFTER
  
  before_destroy { self.following_users.clear }

  # VALIDATIONS

  validates :title, presence: true, length: { maximum: 255 }
  validates :question_id, uniqueness: true, allow_nil: true
  validates :problem_id, uniqueness: true, allow_nil: true
  validates :contest_id, uniqueness: true, allow_nil: true
  validates_with NoWepionCorrectorValidator
  
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
  
  # Gives the last page number
  def last_page
    return Subject.page_with_message_num(self.messages.count)
  end
  
  # Gives the page containing the n-th message
  def self.page_with_message_num(n)
    return [0, ((n-1)/10).floor].max + 1
  end
  
  # Update last_comment_time and last_comment_user_id
  def update_last_comment
    last_message = self.messages.order(:created_at).last
    unless last_message.nil?
      self.update(:last_comment_time    => last_message.created_at,
                  :last_comment_user_id => last_message.user_id)
    end
  end

  # Create subject together with its first message
  def self.create_with_first_message(user_id:, title:, content:, created_at: Time.now, **options)
    subject = Subject.create(title: title, **options)
    Message.create(subject: subject, user_id: user_id, content: content, created_at: created_at)
    return subject
  end
end

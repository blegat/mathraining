#encoding: utf-8

# == Schema Information
#
# Table name: followings
#
#  id                 :integer          not null, primary key
#  kind               :integer          default(NULL)
#  read               :boolean
#  created_at         :datetime         not null
#  submission_id      :integer
#  submission_user_id :integer
#  user_id            :integer
#
# Indexes
#
#  index_followings_on_created_at                       (created_at)
#  index_followings_on_submission_id                    (submission_id)
#  index_followings_on_submission_user_id               (submission_user_id)
#  index_followings_on_user_id_and_kind                 (user_id,kind)
#  index_followings_on_user_id_and_kind_and_created_at  (user_id,kind,created_at)
#  index_followings_on_user_id_and_submission_id        (user_id,submission_id) UNIQUE
#
class Following < ActiveRecord::Base
  
  enum :kind, {:reservation     =>  0,
               :first_corrector =>  1,
               :other_corrector =>  2}

  # BELONGS_TO, HAS_MANY

  belongs_to :submission
  belongs_to :user
  belongs_to :submission_user, class_name: "User" # Could be avoided, but to go faster in users/show

  # VALIDATIONS

  validates :submission_id, uniqueness: { scope: :user_id }
  validates :kind, presence: true
  
  # BEFORE, AFTER
  
  before_validation :set_submission_user_id
  
  # Automatically compute submission_user_id
  def set_submission_user_id
    unless self.submission.nil?
      self.submission_user = self.submission.user
    end
  end

end

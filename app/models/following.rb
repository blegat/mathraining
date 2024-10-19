#encoding: utf-8

# == Schema Information
#
# Table name: followings
#
#  id                 :integer          not null, primary key
#  submission_id      :integer
#  user_id            :integer
#  read               :boolean
#  created_at         :datetime         not null
#  kind               :integer          default(NULL)
#  submission_user_id :integer
#
class Following < ActiveRecord::Base
  
  enum kind: {:reservation     =>  0,
              :first_corrector =>  1,
              :other_corrector =>  2}

  # BELONGS_TO, HAS_MANY

  belongs_to :submission
  belongs_to :user
  belongs_to :submission_user, class_name: "User" # Could be avoided, but to go faster in users/show

  # VALIDATIONS

  validates :user_id, uniqueness: { scope: :submission_id }
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

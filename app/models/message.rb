#encoding: utf-8

# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  erased     :boolean          default(FALSE)
#
class Message < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :subject, optional: true # For creation of first message before subject is created
  belongs_to :user, optional: true # For automatic messages
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :user_id, presence: true # can be 0
  
  # BEFORE, AFTER
  
  after_create { self.subject.update_last_comment }
  after_destroy { self.subject.update_last_comment }
  
  # OTHER METHODS
  
  # Tells if the message can be updated by the given user
  def can_be_updated_by(user)
    if user.root? # Roots can update everything
      return true
    elsif self.user_id > 0 # Not an automatic message
      if self.user == user && !self.erased? # One can always update his own message (unless it is erased)
        return true
      elsif user.admin? && !self.user.admin? # Admins can only update messages from non-admins
        return true
      end
    end
    return false
  end
  
  # Gives the page of the subject containing this message
  def page
    subject = self.subject
    n = subject.messages.where("created_at <= ? OR id = ?", self.created_at, self.id).count # Also compare the id in case <= does not work well for some reason
    return Subject.page_with_message_num(n)
  end
end

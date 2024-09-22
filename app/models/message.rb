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
#
class Message < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :subject
  belongs_to :user, optional: true # For automatic messages
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :user_id, presence: true
  
  # OTHER METHODS
  
  # Tells if the message can be updated by the given user
  def can_be_updated_by(user)
    return Message.message_can_be_updated_by_user(self, user)
  end
  
  # Implementation of can_be_updated_by, also used by Subject class
  def self.message_can_be_updated_by_user(message, user)
    if user.root? # Roots can update everything
      return true
    elsif message.user_id > 0 # Not an automatic message
      if message.user == user # One can always update his own message
        return true
      elsif user.admin? && !message.user.admin? # Admins can only update messages from non-admins
        return true
      end
    end
    return false
  end
  
  # Gives the page of the subject containing this message
  def page
    subject = self.subject
    n = subject.messages.where("created_at <= ? OR id = ?", self.created_at, self.id).count # Also compare the id in case <= does not work well for some reason
    return subject.page_with_message_num(n)
  end
end

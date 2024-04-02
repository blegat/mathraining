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

class SponsorValidator < ActiveModel::Validator
  def validate(record)
    w = Sponsorword.words(record.content)
    if w.size > 10
      record.errors.add(:base, "Message ne peut pas contenir plus de 10 mots contenant les lettres de notre sponsor.")
    else
      some_unused_word = false
      w.each do |x|
        if !x.used?
          some_unused_word = true
          break
        end
      end
      if !some_unused_word
        record.errors.add(:base, "Message doit contenir un mot français inédit contenant les initiales de notre sponsor, dans le bon ordre.")
      end
    end
  end
end

class Message < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :subject
  belongs_to :user, optional: true # For automatic messages
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :user_id, presence: true
  
  validates_with SponsorValidator, on: :create
  after_save :save_used_words
  
  # OTHER METHODS
  
  def save_used_words
    w = Sponsorword.words(self.content)
    w.each do |x|
      if !x.used?
        x.update_attribute(:used, true)
      end
    end
  end
  
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

end

#encoding: utf-8

# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime
#  updated_at :datetime
#
class Message < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :subject
  belongs_to :user
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  validates :user_id, presence: true
  validates :subject_id, presence: true

end

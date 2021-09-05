#encoding: utf-8

# == Schema Information
#
# Table name: tchatmessages
#
#  id            :integer          not null, primary key
#  content       :text
#  user_id       :integer
#  discussion_id :integer
#  created_at    :datetime
#
class Tchatmessage < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :discussion
  belongs_to :user
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice

end

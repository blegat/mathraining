#encoding: utf-8

# == Schema Information
#
# Table name: tchatmessages
#
#  id            :integer          not null, primary key
#  content       :text
#  created_at    :datetime
#  discussion_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_tchatmessages_on_discussion_id                 (discussion_id)
#  index_tchatmessages_on_discussion_id_and_created_at  (discussion_id,created_at) UNIQUE
#  index_tchatmessages_on_user_id                       (user_id)
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

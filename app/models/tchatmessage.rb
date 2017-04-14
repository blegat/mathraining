#encoding: utf-8
# == Schema Information
#
# Table name: tchatmessages
#
#  id            :integer          not null, primary key
#  discussion_id :integer
#  user_id       :integer
#  content       :text
#  created_at    :datetime
#

class Tchatmessage < ActiveRecord::Base
  # attr_accessible :content

  # BELONGS_TO, HAS_MANY

  belongs_to :discussion
  belongs_to :user
  has_many :tchatmessagefiles, dependent: :destroy
  has_many :faketchatmessagefiles, dependent: :destroy

  validates :content, presence: true, length: { maximum: 8000 }
end

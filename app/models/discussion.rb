#encoding: utf-8

# == Schema Information
#
# Table name: discussions
#
#  id                :integer          not null, primary key
#  last_message_time :datetime
#
class Discussion < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  has_many :links, dependent: :destroy
  has_many :users, through: :links
  has_many :tchatmessages, dependent: :destroy

end

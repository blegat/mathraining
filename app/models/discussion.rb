#encoding: utf-8

# == Schema Information
#
# Table name: discussions
#
#  id           :integer          not null, primary key
#  last_message :datetime
#  created_at   :datetime
#  updated_at   :datetime
#
class Discussion < ActiveRecord::Base
  # attr_accessible :last_message

  # BELONGS_TO, HAS_MANY

  # has_many :discussions_users
  has_many :users, through: :links
  has_many :links, dependent: :destroy

  has_many :tchatmessages, dependent: :destroy
end

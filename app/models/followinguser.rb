#encoding: utf-8
# == Schema Information
#
# Table name: followings
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  followed_user_id :integer
#

class Followinguser < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY
  belongs_to :user
  belongs_to :followed_user, class_name: "User"

  # VALIDATIONS
  validates :user_id, presence: true
  validates :followed_user_id, presence: true, uniqueness: { scope: :user_id }
end

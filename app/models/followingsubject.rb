#encoding: utf-8
# == Schema Information
#
# Table name: followings
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  subject_id :integer
#

class Followingsubject < ActiveRecord::Base
  belongs_to :subject
  belongs_to :user

  validates :subject_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :subject_id }

end

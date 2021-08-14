#encoding: utf-8

# == Schema Information
#
# Table name: followingcontests
#
#  id         :integer          not null, primary key
#  contest_id :integer
#  user_id    :integer
#
class Followingcontest < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  belongs_to :user

  # VALIDATIONS

  validates :contest_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :contest_id }
end

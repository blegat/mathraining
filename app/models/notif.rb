#encoding: utf-8

# == Schema Information
#
# Table name: notifs
#
#  id            :integer          not null, primary key
#  submission_id :integer
#  user_id       :integer
#  created_at    :datetime
#  updated_at    :datetime
#
class Notif < ActiveRecord::Base
  # attr_accessible :submission_id

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission

  # VALIDATIONS

  validates :submission_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :submission_id }
end

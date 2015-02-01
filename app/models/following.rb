#encoding: utf-8
# == Schema Information
#
# Table name: followings
#
#  id            :integer          not null, primary key
#  submission_id :integer
#  user_id       :integer
#  read          :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Following < ActiveRecord::Base
  attr_accessible :read

  belongs_to :submission
  belongs_to :user

  validates :submission_id, presence: true
  validates :user_id, presence: true, uniqueness: { scope: :submission_id }
  validates :read, inclusion: { in: [false, true] }
end

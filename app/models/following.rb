#encoding: utf-8
# == Schema Information
#
# Table name: followings
#
#  id            :integer          not null, primary key
#  submission_id :integer
#  user_id       :integer
#  read          :boolean
#  kind          :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
#
#  kind = 0 if reservation
#         1 if first corrector
#         2 if other corrector

class Following < ActiveRecord::Base
  # attr_accessible :read

  # BELONGS_TO, HAS_MANY

  belongs_to :submission
  belongs_to :user

  # VALIDATIONS

  validates :submission_id, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true, uniqueness: { scope: :submission_id }
end

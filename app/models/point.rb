#encoding: utf-8
# == Schema Information
#
# Table name: points
#
#  id        :integer          not null, primary key
#  user_id   :integer
#  rating    :integer
#  forumseen :datetime         not null
#

class Point < ActiveRecord::Base
  # attr_accessible :rating, :forumseen

  # BELONGS_TO, HAS_MANY

  belongs_to :user

  # VALIDATIONS

  validates :rating, presence: true
end

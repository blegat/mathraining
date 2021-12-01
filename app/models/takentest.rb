#encoding: utf-8

# == Schema Information
#
# Table name: takentests
#
#  id             :integer          not null, primary key
#  user_id        :integer
#  virtualtest_id :integer
#  taken_time     :datetime
#  status         :integer
#
class Takentest < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :virtualtest

  # VALIDATIONS

  validates :status, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

end

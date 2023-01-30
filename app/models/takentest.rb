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

  #             :not_started => -1  # used in user.rb (method test_status)
  enum status: {:in_progress =>  0, # started the test but didn't finish yet
                :finished    =>  1} # finished the test

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :virtualtest

  # VALIDATIONS

  validates :status, presence: true

end

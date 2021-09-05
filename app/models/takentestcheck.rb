#encoding: utf-8

# == Schema Information
#
# Table name: takentestchecks
#
#  id           :integer          not null, primary key
#  takentest_id :integer
#
class Takentestcheck < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :takentest

end

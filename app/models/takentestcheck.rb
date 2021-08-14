#encoding: utf-8

# == Schema Information
#
# Table name: takentestchecks
#
#  id           :integer          not null, primary key
#  takentest_id :integer
#
class Takentestcheck < ActiveRecord::Base
  belongs_to :takentest
end

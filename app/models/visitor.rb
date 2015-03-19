#encoding: utf-8
# == Schema Information
#
# Table name: visitors
#
#  id     :integer          not null, primary key
#  number :integer
#  date   :date
#

class Visitor < ActiveRecord::Base
  attr_accessible :number, :date
end

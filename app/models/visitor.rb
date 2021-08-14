#encoding: utf-8

# == Schema Information
#
# Table name: visitors
#
#  id           :integer          not null, primary key
#  date         :date
#  number_user  :integer
#  number_admin :integer
#
class Visitor < ActiveRecord::Base

end

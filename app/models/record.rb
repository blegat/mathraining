#encoding: utf-8
# == Schema Information
#
# Table name: records
#

class Record < ActiveRecord::Base
  def self.update
    r = Record.new
    r.date = DateTime.now.to_date
    r.save
  end
end

#encoding: utf-8

# == Schema Information
#
# Table name: links
#
#  id            :integer          not null, primary key
#  discussion_id :integer
#  user_id       :integer
#  nonread       :integer
#
class Link < ActiveRecord::Base
  # attr_accessible :nonread

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :discussion
end

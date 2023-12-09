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

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :discussion

  validates :nonread, presence: true, numericality: { greater_than_or_equal_to: 0 }
end

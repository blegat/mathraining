#encoding: utf-8

# == Schema Information
#
# Table name: links
#
#  id            :integer          not null, primary key
#  nonread       :integer
#  discussion_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_links_on_discussion_id              (discussion_id)
#  index_links_on_user_id                    (user_id)
#  index_links_on_user_id_and_discussion_id  (user_id,discussion_id) UNIQUE
#
class Link < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :discussion
  
  # VALIDATIONS

  validates :nonread, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discussion_id, uniqueness: { scope: :user_id }
  
end

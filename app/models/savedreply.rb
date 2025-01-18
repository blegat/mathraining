#encoding: utf-8

# == Schema Information
#
# Table name: savedreplies
#
#  id         :bigint           not null, primary key
#  problem_id :bigint
#  content    :text
#  nb_uses    :integer          default(0)
#

class Savedreply < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :problem, optional: true # For generic replies not linked to a problem

  # VALIDATIONS

  validates :problem_id, presence: true # can be 0
  validates :content, presence: true, length: { maximum: 8000 }
  validates :nb_uses, presence: true, numericality: { greater_than_or_equal_to: 0 }

end

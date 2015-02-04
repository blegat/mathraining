#encoding: utf-8
# == Schema Information
#
# Table name: messages
#
#  id         :integer          not null, primary key
#  content    :text
#  subject_id :integer
#  user_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Message < ActiveRecord::Base
  attr_accessible :content
  
  # BELONGS_TO, HAS_MANY
  
  belongs_to :subject
  belongs_to :user
  has_many :messagefiles, dependent: :destroy
  has_many :fakemessagefiles, dependent: :destroy
  
  # VALIDATIONS
  
  validates :content, presence: true
  validates :user_id, presence: true
  validates :subject_id, presence: true
end

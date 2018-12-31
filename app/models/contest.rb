#encoding: utf-8
# == Schema Information
#
# Table name: contests
#
#  id             :integer          not null, primary key
#  number         :integer
#  description    :text
#  status         :integer
#
# status = 0 --> in construction
# status = 1 --> online and not finished
# status = 2 --> online and finished

include ApplicationHelper

class Contest < ActiveRecord::Base
  # BELONGS_TO, HAS_MANY

  has_many :contestscores, dependent: :destroy
  has_many :contestproblems, dependent: :destroy
  has_many :contestorganizations, dependent: :destroy
  has_many :organizers, through: :contestorganizations, source: :user
  has_many :followingcontests, dependent: :destroy
  has_many :followers, through: :followingcontests, source: :user
  
  has_one :subject

  # VALIDATIONS

  validates :status, presence: true
  validates :description, presence: true, length: { maximum: 8000 }
  validates :number, presence: true, numericality: { greater_than: 0 }
  
  def is_organized_by(user)
    return (!user.nil? && organizers.include?(user.sk))
  end
  
  def is_organized_by_or_root(user)
    return ((!user.nil? && user.sk.root?) || is_organized_by(user))
  end
  
  def is_organized_by_or_admin(user)
    return ((!user.nil? && user.sk.admin?) || is_organized_by(user))
  end

end

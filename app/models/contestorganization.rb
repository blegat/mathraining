#encoding: utf-8

# == Schema Information
#
# Table name: contestorganizations
#
#  id         :integer          not null, primary key
#  contest_id :integer
#  user_id    :integer
#
class Contestorganization < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :contest
  belongs_to :user

  # VALIDATIONS

  validates :user_id, uniqueness: { scope: :contest_id }

end

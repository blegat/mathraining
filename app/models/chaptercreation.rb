#encoding: utf-8

# == Schema Information
#
# Table name: chaptercreations
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  chapter_id :integer
#
class Chaptercreation < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :chapter
  belongs_to :user

  # VALIDATIONS

  validates :user_id, uniqueness: { scope: :chapter_id }

end

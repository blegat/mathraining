# == Schema Information
#
# Table name: theories
#
#  id         :integer          not null, primary key
#  content    :text
#  online     :boolean          default(FALSE)
#  position   :integer
#  title      :string
#  chapter_id :integer
#
# Indexes
#
#  index_theories_on_chapter_id  (chapter_id)
#
include ApplicationHelper

class Theory < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :chapter
  has_and_belongs_to_many :users

  # VALIDATIONS

  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 16000 }
  validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

end

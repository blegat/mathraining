# == Schema Information
#
# Table name: theories
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  chapter_id :integer
#  order      :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Theory < ActiveRecord::Base
  attr_accessible :chapter_id, :content, :position, :title
  belongs_to :chapter
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: {maximum: 8000 }
  validates :position, presence: true
end

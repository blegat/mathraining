#encoding: utf-8
# == Schema Information
#
# Table name: corrections
#
#  id            :integer          not null, primary key
#  user_id       :integer
#  submission_id :integer
#  content       :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Correction < ActiveRecord::Base
  # attr_accessible :content

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :user_id, presence: true
  validates :submission_id, presence: true
  validates :content, presence: true, length: { maximum: 8000 }
end

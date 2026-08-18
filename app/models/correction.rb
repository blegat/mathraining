#encoding: utf-8

# == Schema Information
#
# Table name: corrections
#
#  id            :integer          not null, primary key
#  content       :text
#  created_at    :datetime         not null
#  submission_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_corrections_on_submission_id  (submission_id)
#  index_corrections_on_user_id        (user_id)
#
class Correction < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission
  has_many :myfiles, as: :myfiletable, dependent: :destroy
  has_many :fakefiles, as: :fakefiletable, dependent: :destroy

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
  
  # BEFORE, AFTER
  
  after_create { self.submission.update_last_comment }
  after_destroy { self.submission.update_last_comment }

end

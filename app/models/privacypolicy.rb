#encoding: utf-8

# == Schema Information
#
# Table name: privacypolicies
#
#  id          :integer          not null, primary key
#  content     :text
#  description :text
#  publication :datetime
#  online      :boolean          default(FALSE)
#
class Privacypolicy < ActiveRecord::Base

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 32000 } # Limited to 16000 in the form but end-of-lines count twice
  validates :description, presence: true, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
end

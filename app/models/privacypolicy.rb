#encoding: utf-8
# == Schema Information
#

class Privacypolicy < ActiveRecord::Base
  # VALIDATIONS
  validates :content, length: { maximum: 32000 } # Limited to 16000 in the form but end-of-lines count twice
  validates :description, length: { maximum: 16000 } # Limited to 8000 in the form but end-of-lines count twice
end

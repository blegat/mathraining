#encoding: utf-8
# == Schema Information
#

class Privacypolicy < ActiveRecord::Base
  # VALIDATIONS
  validates :content, length: { maximum: 16000 }
  validates :description, length: { maximum: 8000 }
end

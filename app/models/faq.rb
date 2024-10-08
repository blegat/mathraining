#encoding: utf-8

# == Schema Information
#
# Table name: faqs
#
#  id       :bigint           not null, primary key
#  question :text
#  answer   :text
#  position :integer
#
class Faq < ActiveRecord::Base

  # VALIDATIONS

  validates :question, presence: true, length: { maximum: 1000 }
  validates :answer, presence: true, length: { maximum: 16000 }
  validates :position, presence: true, numericality: { greater_than: 0 }

end

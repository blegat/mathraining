#encoding: utf-8

# == Schema Information
#
# Table name: faqs
#
#  id       :integer          not null, primary key
#  question :text
#  answer   :text
#  position :integer
#
class Faq < ActiveRecord::Base

  # VALIDATIONS

  validates :question, presence: true, length: { maximum: 1000 }
  validates :answer, presence: true, length: { maximum: 16000 }

end

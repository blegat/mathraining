#encoding: utf-8

# == Schema Information
#
# Table name: actualities
#
#  id         :integer          not null, primary key
#  title      :string
#  content    :text
#  created_at :datetime         not null
#
class Faq < ActiveRecord::Base

  # VALIDATIONS

  validates :question, presence: true, length: { maximum: 1000 }
  validates :answer, presence: true, length: { maximum: 16000 }

end

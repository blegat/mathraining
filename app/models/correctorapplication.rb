#encoding: utf-8

# == Schema Information
#
# Table name: correctorapplications
#
#  id              :bigint           not null, primary key
#  user_id         :bigint
#  content         :text
#  processed       :boolean          default(FALSE)
#  tchatmessage_id :bigint
#  created_at      :datetime         not null
#

class Correctorapplication < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :tchatmessage, optional: true

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 }
  
end

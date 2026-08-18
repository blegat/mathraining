#encoding: utf-8

# == Schema Information
#
# Table name: correctorapplications
#
#  id              :bigint           not null, primary key
#  content         :text
#  processed       :boolean          default(FALSE)
#  created_at      :datetime         not null
#  tchatmessage_id :bigint
#  user_id         :bigint
#
# Indexes
#
#  index_correctorapplications_on_tchatmessage_id  (tchatmessage_id)
#  index_correctorapplications_on_user_id          (user_id)
#

class Correctorapplication < ActiveRecord::Base

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :tchatmessage, optional: true

  # VALIDATIONS

  validates :content, presence: true, length: { maximum: 16000 }
  
end

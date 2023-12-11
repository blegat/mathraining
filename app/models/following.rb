#encoding: utf-8

# == Schema Information
#
# Table name: followings
#
#  id            :integer          not null, primary key
#  submission_id :integer
#  user_id       :integer
#  read          :boolean
#  created_at    :datetime         not null
#  kind          :integer          default(NULL)
#
class Following < ActiveRecord::Base
  
  enum kind: {:reservation     =>  0,
              :first_corrector =>  1,
              :other_corrector =>  2}

  # BELONGS_TO, HAS_MANY

  belongs_to :submission
  belongs_to :user

  # VALIDATIONS

  validates :user_id, uniqueness: { scope: :submission_id }
  validates :kind, presence: true

end

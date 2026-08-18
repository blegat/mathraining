#encoding: utf-8

# == Schema Information
#
# Table name: starproposals
#
#  id            :bigint           not null, primary key
#  answer        :string
#  reason        :string
#  status        :integer          default("waiting_treatment")
#  created_at    :datetime         not null
#  submission_id :bigint
#  user_id       :bigint
#
# Indexes
#
#  index_starproposals_on_created_at     (created_at)
#  index_starproposals_on_status         (status)
#  index_starproposals_on_submission_id  (submission_id)
#  index_starproposals_on_user_id        (user_id)
#
class Starproposal < ActiveRecord::Base
  
  enum :status, {:waiting_treatment => 0, # to be checked by a root
                 :accepted          => 1, # star confirmed by a root (and star given to submission)
                 :rejected          => 2} # root does not think it deserves a star

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission

  # VALIDATIONS

  validates :reason, presence: true, length: { maximum: 2000 }
  validates :answer, length: { maximum: 2000 }
  
  # OTHER METHODS

  # Gives the class to use to show this star proposal
  def color_class
    if waiting_treatment?
      return "warning"
    elsif accepted?
      return "success"
    else
      return "danger"
    end
  end
  
  # Gives the string for the status
  def status_string
    if waiting_treatment?
      return "En attente"
    elsif accepted?
      return "Accepté"
    else
      return "Rejeté"
    end
  end
  
end

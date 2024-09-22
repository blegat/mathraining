#encoding: utf-8

# == Schema Information
#
# Table name: suspicions
#
#  id            :bigint           not null, primary key
#  submission_id :bigint
#  user_id       :bigint
#  source        :text
#  status        :integer          default("waiting_confirmation")
#  created_at    :datetime         not null
#
class Suspicion < ActiveRecord::Base
  
  enum status: {:waiting_confirmation => 0, # to be confirmed by a root
                :confirmed            => 1, # plagiarism confirmed by a root (and submission marked as plagiarized)
                :forgiven             => 2, # possible plagiarism but forgiven
                :rejected             => 3} # root does not think this is plagiarism

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission

  # VALIDATIONS

  validates :user_id, presence: true
  validates :submission_id, presence: true
  validates :source, presence: true, length: { maximum: 1000 }
  
  # OTHER METHODS

  # Gives the class to use to show this suspicion
  def color_class
    if waiting_confirmation?
      return "warning"
    elsif confirmed?
      return "success"
    else
      return "danger"
    end
  end
  
  # Gives the string for the status
  def status_string
    if waiting_confirmation?
      return "À confirmer"
    elsif confirmed?
      return "Confirmé"
    elsif forgiven?
      return "Pardonné"
    else
      return "Rejeté"
    end
  end
  
end

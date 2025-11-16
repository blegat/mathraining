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
#  cheating_type :integer          default("plagiarism")
#

class SuspicionSourceValidator < ActiveModel::Validator
  def validate(record)
    return if record.usage_of_ai? # No source needed
    if record.source.nil? || record.source.size == 0
      record.errors.add(:base, "Source doit être rempli(e).")
    end
  end
end

class Suspicion < ActiveRecord::Base
  
  enum status: {:waiting_confirmation => 0, # to be confirmed by a root
                :confirmed            => 1, # cheating confirmed by a root (and submission marked as plagiarized or generated_with_ai)
                :forgiven             => 2, # possible plagiarism but forgiven
                :rejected             => 3} # root does not think this is plagiarism
                
  enum cheating_type: {:plagiarism  => 0,
                       :usage_of_ai => 1}

  # BELONGS_TO, HAS_MANY

  belongs_to :user
  belongs_to :submission

  # VALIDATIONS

  validates :source, length: { maximum: 1000 }
  validates_with SuspicionSourceValidator
  
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

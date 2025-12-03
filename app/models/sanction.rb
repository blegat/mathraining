#encoding: utf-8

# == Schema Information
#
# Table name: sanctions
#
#  id            :bigint           not null, primary key
#  user_id       :bigint
#  sanction_type :integer
#  start_time    :datetime
#  duration      :integer
#  reason        :text
#

class Sanction < ActiveRecord::Base
  
  enum sanction_type: {:ban           => 0, # cannot connect to the account
                       :no_submission => 1, # cannot send a submission or a comment
                       :not_corrected => 2} # submissions will not be corrected

  # BELONGS_TO, HAS_MANY

  belongs_to :user

  # VALIDATIONS

  validates :sanction_type, presence: true
  validates :start_time, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true, length: { maximum: 2000 }
  
  # OTHER METHODS
  
  # End date of sanction
  def end_date
    return self.start_time.in_time_zone.to_date + (self.duration).days
  end
  
  # Message shown to user
  def message
    if self.start_time < DateTime.new(2025, 12, 3, 14, 0, 0) # Before, the message contained everything, with [DATE] for the date
      return self.reason.sub("[DATE]", write_date_only(self.end_date))
    elsif self.ban?
      return "Ce compte a été temporairement désactivé jusqu'au #{write_date_only(self.end_date)}. #{self.reason}"
    elsif self.no_submission?
      return "Il ne vous est plus possible de faire de nouvelles soumissions ou d'écrire de nouveaux commentaires jusqu'au #{write_date_only(self.end_date)}. #{self.reason}"
    end
  end
end

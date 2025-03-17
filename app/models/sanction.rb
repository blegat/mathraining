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

class SanctionReasonValidator < ActiveModel::Validator
  def validate(record)
    return if record.not_corrected? # The message is not shown so we don't need [DATE]
    if record.reason.nil? || record.reason.scan(/(?=\[DATE\])/).count != 1
      record.errors.add(:base, "Le message doit contenir exactement une fois '[DATE]'.")
    end
  end
end

class Sanction < ActiveRecord::Base
  
  enum sanction_type: {:ban           => 0, # cannot connect to the account
                       :no_submission => 1, # cannot send a submission or a comment
                       :not_corrected => 2} # submissions will not be corrected

  # BELONGS_TO, HAS_MANY

  belongs_to :user

  # VALIDATIONS

  validates :user_id, presence: true
  validates :sanction_type, presence: true
  validates :start_time, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :reason, presence: true, length: { maximum: 2000 }
  
  validates_with SanctionReasonValidator
  
  # OTHER METHODS
  
  # End date time of sanction
  def end_time
    return self.start_time + (self.duration).days
  end
  
  def message
    return self.reason.sub("[DATE]", write_date_only(self.end_time))
  end
end

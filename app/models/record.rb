	#encoding: utf-8

# == Schema Information
#
# Table name: records
#
#  id                  :integer          not null, primary key
#  date                :date
#  nb_submissions      :integer
#  nb_questions_solved :integer
#  avg_correction_time :float
#  complete            :boolean
#
class Record < ActiveRecord::Base

  # VALIDATIONS
  
  validates :date, uniqueness: true
  
  # OTHER METHODS

  # Update the statistics, if possible (done every day at 2 am (see schedule.rb))
  def self.update
    mondaybeforelastmonday = get_monday_before_last_monday
    lastrecord = Record.order(:date).last
    if(lastrecord.nil?)
      lastdate = Date.parse('1-12-2014')
    else
      lastdate = lastrecord.date
    end
    curmonday = lastdate+7
    while(curmonday <= mondaybeforelastmonday)
      nextmonday = curmonday+7
      nb_submissions = Submission.where.not(:status => :draft).where("created_at >= ? AND created_at < ?", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      nb_questions_solved = Solvedquestion.where("resolution_time >= ? AND resolution_time < ?", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      r = Record.create(:date                => curmonday,
                        :nb_submissions      => nb_submissions,
                        :nb_questions_solved => nb_questions_solved,
                        :complete            => false)
      curmonday = nextmonday
    end

    Record.where(:complete => false).each do |r|
      curmonday = r.date
      nextmonday = curmonday+7
      curmonday_time = curmonday.to_time.to_datetime
      nextmonday_time = nextmonday.to_time.to_datetime
      
      if Submission.where(:status => :waiting).where("created_at >= ? AND created_at < ?", curmonday_time, nextmonday_time).count > 0
        next # not all submissions were corrected
      end

      total = 0
      number = 0
      Submission.where.not(:status => [:draft, :waiting_forever]).where("created_at >= ? AND created_at < ?", curmonday_time, nextmonday_time).each do |s|
        first_correction = s.corrections.where("user_id != ?", s.user_id).order(:created_at).first
        unless first_correction.nil? # can happen for a plagiarized submission without any correction
          total += (first_correction.created_at - s.created_at)/(60*60*24).to_f
          number += 1
        end
      end

      if number > 0
        r.avg_correction_time = total/number.to_f
      else
        r.avg_correction_time = 0
      end
      r.complete = true
      r.save
    end
  end
  
  # Helper method to get the monday before the last monday
  def self.get_monday_before_last_monday
    today = Date.today
    yesterday = today-1
    last_sunday = yesterday - yesterday.wday
    return last_sunday-6
  end
end

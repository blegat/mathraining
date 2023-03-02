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
      nb_submissions = Submission.where("status != ? AND created_at >= ? AND created_at < ?", Submission.statuses[:draft], curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      nb_questions_solved = Solvedquestion.where("correct = ? AND resolution_time >= ? AND resolution_time < ?", true, curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      r = Record.create(:date                => curmonday,
                        :nb_submissions      => nb_submissions,
                        :nb_questions_solved => nb_questions_solved,
                        :complete            => false)
      curmonday = nextmonday
    end

    Record.where(:complete => false).each do |r|
      curmonday = r.date
      nextmonday = curmonday+7
      if(Submission.where("created_at >= ? AND created_at < ? AND status = ?", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime, Submission.statuses[:waiting]).count > 0)
        next # not all submissions are corrected
      end

      total = 0
      number = 0
      Submission.where("created_at >= ? AND created_at < ? AND status != ?", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime, Submission.statuses[:draft]).each do |s|
        submission_date = s.created_at
        first_correction = s.corrections.where("user_id != ?", s.user_id).order(:created_at).first
        unless first_correction.nil? # can happen for a plagiarized submission without any correction
          first_correction_date = first_correction.created_at
          total = total + (first_correction_date - submission_date)/(60*60*24).to_f
          number = number+1
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
    today = DateTime.now.in_time_zone.to_date
    yesterday = today-1
    last_sunday = yesterday - yesterday.wday
    return last_sunday-6
  end
end

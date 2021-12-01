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

  # Mets à jour les statistiques, si possible (fait tous les jours à 2 heures du matin (voir schedule.rb))
  def self.update
    mondaybeforelastmonday = get_monday_before_last_monday(DateTime.now.in_time_zone.to_date)
    lastrecord = Record.order(:date).last
    if(lastrecord.nil?)
      lastdate = Date.parse('1-12-2014')
    else
      lastdate = lastrecord.date
    end
    curmonday = lastdate+7
    while(curmonday <= mondaybeforelastmonday)
      nextmonday = curmonday+7
      r = Record.new
      r.date = curmonday
      r.nb_submissions = Submission.where("status != -1 AND created_at >= ? AND created_at < ?", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      r.nb_questions_solved = Solvedquestion.where("correct = ? AND resolution_time >= ? AND resolution_time < ?", true, curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count
      r.complete = false
      r.save
      curmonday = nextmonday
    end

    Record.where(:complete => false).each do |r|
      curmonday = r.date
      nextmonday = curmonday+7
      if(Submission.where("created_at >= ? AND created_at < ? AND status == 0", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).count > 0)
        next # not all submissions are corrected
      end

      total = 0
      number = 0
      Submission.where("created_at >= ? AND created_at < ? AND status != -1", curmonday.to_time.to_datetime, nextmonday.to_time.to_datetime).each do |s|
        submission_date = s.created_at
        first_correction_date = s.corrections.where("user_id != ?", s.user_id).order(:created_at).first.created_at
        total = total + (first_correction_date - submission_date)/(60*60*24).to_f
        number = number+1
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
  
  def self.get_monday_before_last_monday(today)
    yesterday = today-1
    lastdimanche = yesterday - yesterday.wday
    return lastdimanche-6
  end
end

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
      
      # check submissions not in a test
      if Submission.where(:status => :waiting, :intest => :false).where("created_at >= ? AND created_at < ?", curmonday_time, nextmonday_time).count > 0
        next # not all submissions were corrected
      end
      
      # check submissions in a test (the time used to compute correction time is the moment where the test ended, intead of s.created_at)
      all_subs_in_test_corrected = true
      modified_start_for_test = curmonday-2 # hardcoded, knowing that the longest test lasts for 2 days
      modified_start_for_test_time = modified_start_for_test.to_time.to_datetime
      Submission.where(:status => :waiting, :intest => :true).where("created_at >= ? AND created_at < ?", modified_start_for_test_time, nextmonday_time).each do |s|
        p = s.problem
        t = p.virtualtest
        date_start = t.takentests.where(:user_id => s.user_id).first.taken_time
        date_sub = date_start + (t.duration).minutes
        if date_sub >= curmonday_time and date_sub < nextmonday_time
          all_subs_in_test_corrected = false
        end
      end
      
      unless all_subs_in_test_corrected
        next # not all submissions from a test were corrected
      end

      total = 0
      number = 0
      Submission.where.not(:status => [:draft, :waiting_forever]).where("created_at >= ? AND created_at < ? AND (intest = ? OR created_at >= ?)", modified_start_for_test_time, nextmonday_time, true, curmonday_time).each do |s|
        submission_date = s.created_at
        if s.intest?
          p = s.problem
          t = p.virtualtest
          date_start = t.takentests.where(:user_id => s.user_id).first.taken_time
          submission_date = date_start + (t.duration).minutes
        end
        if submission_date >= curmonday_time and submission_date < nextmonday_time
          first_correction = s.corrections.where("user_id != ?", s.user_id).order(:created_at).first
          unless first_correction.nil? # can happen for a plagiarized submission without any correction
            first_correction_date = first_correction.created_at
            total = total + (first_correction_date - submission_date)/(60*60*24).to_f
            number = number+1
          end
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

#encoding: utf-8

module ContestConcern
  extend ActiveSupport::Concern
  
  protected
  
  # Check that current user is an organizer of @contest
  def organizer_of_contest
    if !(signed_in? && @contest.is_organized_by(current_user))
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is a root or an organizer of @contest
  def organizer_of_contest_or_root
    if !(signed_in? && @contest.is_organized_by_or_root(current_user))
      render 'errors/access_refused'
    end
  end
  
  # Check that current user is an admin or an organizer of @contest
  def organizer_of_contest_or_admin
    if !(signed_in? && @contest.is_organized_by_or_admin(current_user))
      render 'errors/access_refused'
    end
  end
  
  # Check if a contest problem just started or ended (done only when charging a contest related page)
  def check_contests
    date_now = DateTime.now
    # Note: Problems in Contestproblemcheck are also used in contest.rb to check problems for which an email or forum subject must be created
    Contestproblemcheck.all.order(:id).each do |c|
      p = c.contestproblem
      if p.not_started_yet? # Contest is online but problem is not published yet
        if p.start_time <= date_now
          p.in_progress!
        end
      end
      if p.in_progress? # Problem has started but not ended
        if p.end_time <= date_now
          p.in_correction!
          contest = p.contest
          if contest.contestproblems.where(:status => [:not_started_yet, :in_progress]).count == 0 # All problems of the contest are finished: mark the contest as finished
            contest.in_correction!
          end
        end
      end
      if p.at_least(:in_correction) && p.all_reminders_sent? # Avoid to delete if reminders were not sent yet
        c.destroy
      end
    end
  end
end

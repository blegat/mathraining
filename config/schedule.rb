# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

every :hour, at: 0  do
  runner "Contest.check_contests_starts" # Send mail and post messages on forum for contests
end

every :day, :at => '2am' do
  runner "Record.update"                  # Update statistics for problems and questions
  runner "Globalstatistic.get.update_all" # Update global statistics on front page (just in case)
  runner "Myfile.fake_dels"               # Delete old files
  runner "User.delete_unconfirmed"        # Delete users with unconfirmed email
end

every :monday, :at => '3am' do
  runner "Chapter.update_all_stats" # Update statistics for chapters (not so important, so done once a week)
end

every :tuesday, :at => '3am' do
  runner "Question.update_all_stats" # Update statistics for questions (not so important, so done once a week)
end

every :wednesday, :at => '3am' do
  runner "Problem.update_all_stats" # Update statistics for problems (not so important, so done once a week)
end

every :day, :at => '12am' do
  runner "Visitor.compute"  # Compute the number of visitors of the day before
end

every :day, :at => '12:03am' do
  runner "Solvedquestion.detect_suspicious_users" # Search for suspicious users and post a message on forum if needed
end

every 14.minutes do
  runner "Discussion.answer_puzzle_questions(1)" # Answer to tchatmessages addressed to C.-J. de L. V. P.
end

every 23.minutes do
  runner "Discussion.answer_puzzle_questions(2)" # Answer to tchatmessages addressed to J. H.
end

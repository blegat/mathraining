#!bin/rails runner

def export_rating_history
  $history = []
  x = 0
  last_user_id = User.ids.max
  f = File.open("./rating_history.csv", "w")
  f.write("user id ; user name ; gender ; registered")
  
  date_start = Date.new(2014, 12, 1)
  date_end = date_start + 1.month
  while date_start <= Date.today
    f.write(" ; #{date_start.month}/#{date_start.year}")
    if x == 0
      $history[x] = Array.new(last_user_id, 0)
    else
      $history[x] = $history[x-1].dup
    end
    
    Solvedquestion.joins(question: [{ chapter: :section }]).select("questions.level, solvedquestions.user_id").where("resolution_time >= ? AND resolution_time < ? AND sections.fondation = ? AND correct = ?", date_start, date_end, false, true).each do |sq|
      $history[x][sq.user_id] = $history[x][sq.user_id] + 3 * sq.level
    end
    
    Solvedproblem.joins(:problem).select("problems.level, solvedproblems.user_id").where("resolution_time >= ? AND resolution_time < ?", date_start, date_end).each do |sp|
      $history[x][sp.user_id] = $history[x][sp.user_id] + 15 * sp.level
    end
  
    date_start = date_end
    date_end = date_start + 1.month
    x = x+1
  end
  
  f.write("\n")
  User.select("id, sex, first_name, last_name, see_name, created_at").where("admin = ? AND active = ? AND rating > ?", false, true, 0).order(:id).each do |u|
    f.write("#{u.id} ; #{u.name} ; #{u.sex == 0 ? 'M' : 'F'} ; #{u.created_at.day}/#{u.created_at.month}/#{u.created_at.year}")
    for i in 0..(x-1) do
      f.write("; #{$history[i][u.id]}")
    end
    f.write("\n")
  end
  
  f.close
end

module ProblemsHelper

  private
  
  # Get all non-accessible problems ids, for the current user (it's faster to get non-accessible problems than accessible ones!)
  def non_accessible_problems_ids(user, section = nil) # user = nil for non-signed-in user
    return "all" if !has_enough_points(user)
    
    return Set.new if user.admin?
    
    problems_without_real_submission_condition = (@no_new_submission ? "OR problems.id NOT IN #{problems_with_real_submission_request(user)}" : "")
    
    section_condition = (!section.nil? ? "problems.section_id = #{section.id} AND" : "")
        
    return Problem.find_by_sql("SELECT problems.id
                                FROM problems
                                LEFT JOIN chapters_problems
                                ON chapters_problems.problem_id = problems.id
                                WHERE #{section_condition} 
                                  (problems.online = false
                                   OR (problems.virtualtest_id > 0
                                       AND problems.virtualtest_id NOT IN #{virtualtests_done_request(user)})
                                   OR (problems.virtualtest_id = 0
                                       AND ((chapters_problems.chapter_id IS NOT NULL
                                             AND chapters_problems.chapter_id NOT IN #{chapters_completed_request(user)})
                                            #{problems_without_real_submission_condition})))").pluck(:id).to_set
  end
  
  # Get all accessible problems of one section, for the current user
  def accessible_problems_from_section(user, section, columns) # user = nil for a non-signed-in user
    return [] if !has_enough_points(user)
    
    return section.problems.select(get_problem_columns_string(columns)).order("level, number") if user.admin?
    
    ids_to_reject = non_accessible_problems_ids(user, section).to_a
    
    return section.problems.select(get_problem_columns_string(columns)).where.not(:id => ids_to_reject).order("level, number")
  end
  
  def get_problem_columns_string(columns)
    columns_string = ""
    columns.each do |c|
      columns_string = columns_string + ", " unless columns_string.empty?
      columns_string = columns_string + "problems." + c
    end
    return columns_string
  end
  
  def virtualtests_done_request(user)
    return "(" + user.takentests.select(:virtualtest_id).where(:status => :finished).to_sql + ")"
  end
  
  def problems_with_real_submission_request(user)
    return "(SELECT DISTINCT submissions.problem_id
             FROM submissions
             WHERE submissions.user_id = #{user.id}
             AND submissions.status != #{Submission.statuses[:draft]})"
  end
end

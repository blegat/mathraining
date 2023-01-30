module ProblemsHelper

  private
  
  # Get all accessible problems, for the current user
  def accessible_problems(columns)
    return [] if !has_enough_points
    
    return Problems.select(get_problem_columns_string(column)) if current_user.sk.admin?
    
    return Problem.find_by_sql("SELECT #{get_problem_columns_string(columns)}
                                FROM problems
                                WHERE problems.online = #{true_value_sql}
                                AND (problems.virtualtest_id IN #{virtualtests_done_request}
                                     OR (problems.virtualtest_id = 0
                                         AND #{num_problem_unsolved_prerequisites_request} = 0
                                        )
                                    )")
  end
  
  # Get all accessible problems of one section, for the current user
  def accessible_problems_from_section(section, columns)
    return [] if !has_enough_points
    
    return section.problems.select(get_problem_columns_string(columns)).order("level, number") if current_user.sk.admin?
    
    return Problem.find_by_sql("SELECT #{get_problem_columns_string(columns)}
                                FROM problems
                                WHERE problems.section_id = #{section.id}
                                AND problems.online = #{true_value_sql}
                                AND (problems.virtualtest_id IN #{virtualtests_done_request}
                                     OR (problems.virtualtest_id = 0
                                         AND #{num_problem_unsolved_prerequisites_request} = 0
                                        )
                                    )
                                ORDER BY problems.level, problems.number")
  end
  
  def get_problem_columns_string(columns)
    columns_string = ""
    columns.each do |c|
      columns_string = columns_string + ", " unless columns_string.empty?
      columns_string = columns_string + "problems." + c
    end
    return columns_string
  end
  
  def virtualtests_done_request
    return "(" + current_user.sk.takentests.select(:virtualtest_id).where(:status => :finished).to_sql + ")"
  end
  
  def num_problem_unsolved_prerequisites_request
    return "(SELECT COUNT (chapters_problems.chapter_id)
             FROM chapters_problems
             WHERE chapters_problems.problem_id = problems.id
             AND chapters_problems.chapter_id NOT IN #{chapters_completed_request})"
  end

end

module ProblemsHelper

  private

  # Tells if all chapters prerequisite of a problem are completed by some user
  # Array chapters_completion should contain true for each completed chapter (see get_chapters_completion)
  def is_problem_accessible(problem, chapters_completion)
    problem.chapters.each do |c|
      if !chapters_completion[c.id]
        return false
      end
    end
    return true
  end

end

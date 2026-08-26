module QuestionsHelper

  private
  
  # Get all accessible question ids for which the current user can see the solution
  def fully_accessible_questions_ids(user)
    return Set.new if user.nil?
    
    return "all" if user.admin?
    
    return user.solvedquestions.pluck(:question_id).to_set
  end
end

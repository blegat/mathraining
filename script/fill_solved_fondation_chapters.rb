#!bin/rails runner

$result = {}

def fill_solved_fondation_chapters(apply = false)
  fondation_sec = Section.where(:fondation => true).first
  fondation_sec.chapters.where(:online => true).each do |chapter|
    chapter_set = Set.new
    first_question = true
    chapter.questions.where(:online => true).each do |question|
      question_set = Set.new
      question.solvedquestions.where(:correct => true).select(:user_id).each do |sq|
        question_set.add(sq.user_id)
      end
      if first_question
        chapter_set = question_set
        first_question = false
      else
        chapter_set = chapter_set.intersection(question_set)
      end
    end
    $result[chapter.id] = chapter_set
    if apply
      chapter_set.each do |user_id|
        unless chapter.users.exists?(user_id)
          chapter.users << User.find(user_id)
        end
      end
    end
  end
end

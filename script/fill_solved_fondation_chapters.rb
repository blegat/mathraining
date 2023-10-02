#!bin/rails runner

$result = {}

def fill_solved_fondation_chapters(apply = false)
  fondation_sec = Section.where(:fondation => true).first
  fondation_sec.chapters.where(:online => true).each do |chapter|
    chapter_set = Set.new
    first_question = true
    chapter.questions.where(:online => true).each do |question|
      question_set = Set.new
      question.users.select(:id).each do |user|
        question_set.add(user)
      end
      if first_question
        chapter_set = question_set
      else
        chapter_set = chapter_set.intersection(question_set)
      end
    end
    $result[chapter.id] = chapter_set
    if apply
      chapter_set.each do |user|
        chapter.users << user
      end
    end
  end
end

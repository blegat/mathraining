module ChaptersHelper

  private

  # Compute an array with 'true" for each completed chapter
  # Array section_fondation should tell which section is a fondation
  def get_chapters_completion(section_fondation)
    completed = Array.new
    Chapter.all.each do |c|
      completed[c.id] = section_fondation[c.section_id]
    end

    if @signed_in
      current_user.sk.chapters.each do |c|
        completed[c.id] = true
      end
    end

    return completed
  end

  # Tells if exercises of a chapter are accessible by a user
  # Array section_fondation should tell which section is a fondation
  # Array chapters_completion should contain true for each completed chapter (see get_chapters_completion)
  def are_exercises_accessible(chapter, section_fondation, chapters_completion)
    if !section_fondation[chapter.section_id]
      chapter.prerequisites.each do |p|
        if !chapters_completion[p.id]
          return false
        end
      end
    end
    return true
  end

end

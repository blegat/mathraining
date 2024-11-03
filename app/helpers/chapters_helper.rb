module ChaptersHelper

  def user_can_write_chapter(user, chapter)
    return false if user.nil?
    if @cached_user_1 == user && @cached_chapter_1 == chapter
      return @cached_user_can_write_chapter
    end
    @cached_user_1 = user
    @cached_chapter_1 = chapter
    @cached_user_can_write_chapter = (user.admin? || user.creating_chapters.exists?(chapter.id))
    return @cached_user_can_write_chapter
  end
  
  def user_can_see_chapter_exercises(user, chapter)
    if @cached_user_2 == user && @cached_chapter_2 == chapter
      return @cached_user_can_see_chapter_exercises
    end
    @cached_user_2 = user
    @cached_chapter_2 = chapter
    @cached_user_can_see_chapter_exercises = true
    if !chapter.section.fondation? && !user_can_write_chapter(user, chapter) 
      chapter.prerequisites_associations.select(:prerequisite_id).each do |p|
        if user.nil? || !user.chapters.exists?(p.prerequisite_id)
          @cached_user_can_see_chapter_exercises = false
          break
        end
      end
    end
    return @cached_user_can_see_chapter_exercises
  end

  private

  # Returns the chapters ids for which we cannot see/solve the exercises (it's faster to get non-accessible problems than accessible ones!)
  def non_accessible_chapters_ids(user, section = nil) # user = nil for non-signed-in user
    return Set.new if (!user.nil? and user.admin?)
    
    section_condition = (!section.nil? ? "chapters.section_id = #{section.id} AND" : "")
    
    return Chapter.find_by_sql("SELECT chapters.id
                                FROM chapters
                                LEFT JOIN prerequisites
                                ON prerequisites.chapter_id = chapters.id
                                WHERE #{section_condition}
                                  (chapters.online = false
                                   OR (chapters.section_id NOT IN #{fondations_sections_request}
                                       AND prerequisites.prerequisite_id IS NOT NULL
                                       AND prerequisites.prerequisite_id NOT IN #{chapters_completed_request(user)}))").pluck(:id).to_set
  end
  
  def fondations_sections_request
    return "(" + Section.where(:fondation => true).select(:id).to_sql + ")"
  end
  
  def chapters_completed_request(user)
    if user.nil?
      return "(0)" # We put 0 because PG does not seem to support empty list
    else
      return "(SELECT chapter_id FROM chapters_users WHERE chapters_users.user_id = #{user.id})"
    end
  end
end

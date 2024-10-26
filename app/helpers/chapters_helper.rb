module ChaptersHelper

  private

  # Returns the chapters for which we can see/solve the exercises
  #def accessible_chapters(user) # user = nil for a non-signed-in user
  #  return Chapter.select(:id) if (!user.nil? and user.admin?)
  #  
  #  return Chapter.find_by_sql("SELECT chapters.id
  #                              FROM chapters
  #                              WHERE chapters.online = true
  #                              AND (chapters.section_id IN #{fondations_sections_request}
  #                                   OR #{num_chapter_unsolved_prerequisites_request(user)} = 0
  #                                  )")
  #end
  
  # Returns the chapters ids for which we cannot see/solve the exercises
  def non_accessible_chapters_ids(user) # user = nil for non-signed-in user
    return Set.new if (!user.nil? and user.admin?)
    
    return Chapter.find_by_sql("SELECT chapters.id
                                FROM chapters
                                LEFT JOIN prerequisites
                                ON prerequisites.chapter_id = chapters.id
                                WHERE chapters.online = false
                                OR (chapters.section_id NOT IN #{fondations_sections_request}
                                    AND prerequisites.prerequisite_id IS NOT NULL
                                    AND prerequisites.prerequisite_id NOT IN #{chapters_completed_request(user)}
                                   )").pluck(:id).to_set
  end
  
  # Returns the chapters of one section for which we can solve the exercises
  def accessible_chapters_from_section(user, section) # user = nil for a non-signed-in user
    return section.chapters.select(:id) if (!user.nil? and user.admin?)
    
    if section.fondation?
      return section.chapters.select(:id).where(:online => true)
    else
      return Chapter.find_by_sql("SELECT chapters.id
                                  FROM chapters
                                  WHERE chapters.section_id = #{section.id}
                                  AND chapters.online = true
                                  AND #{num_chapter_unsolved_prerequisites_request(user)} = 0")
    end
  end
  
  def num_chapter_unsolved_prerequisites_request(user)
    return "(SELECT COUNT(prerequisites.prerequisite_id)
             FROM prerequisites
             WHERE prerequisites.chapter_id = chapters.id
             AND prerequisites.prerequisite_id NOT IN #{chapters_completed_request(user)})"
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

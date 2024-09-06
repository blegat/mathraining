module ChaptersHelper

  private

  # Returns the chapters for which we can see/solve the exercises
  def accessible_chapters(user, columns) # user = nil for a non-signed-in user
    return Chapter.select(get_chapter_columns_string(columns)) if (!user.nil? and user.admin?)
    
    return Chapter.find_by_sql("SELECT #{get_chapter_columns_string(columns)}
                                FROM chapters
                                WHERE chapters.online = true
                                AND (chapters.section_id IN #{fondations_sections_request}
                                     OR #{num_chapter_unsolved_prerequisites_request(user)} = 0
                                    )")
  end
  
  # Returns the chapters of one section for which we can solve the exercises
  def accessible_chapters_from_section(user, section, columns) # user = nil for a non-signed-in user
    return section.chapters.select(get_chapter_columns_string(columns)) if (!user.nil? and user.admin?)
    
    if section.fondation?
      return section.chapters.select(get_chapter_columns_string(columns)).where(:online => true)
    else
      return Chapter.find_by_sql("SELECT #{get_chapter_columns_string(columns)}
                                  FROM chapters
                                  WHERE chapters.section_id = #{section.id}
                                  AND chapters.online = true
                                  AND #{num_chapter_unsolved_prerequisites_request(user)} = 0")
    end
  end
  
  def get_chapter_columns_string(columns)
    columns_string = ""
    columns.each do |c|
      columns_string = columns_string + ", " unless columns_string.empty?
      columns_string = columns_string + "chapters." + c
    end
    return columns_string
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
      return "(" + user.chapters.select(:id).to_sql + ")"
    end
  end
end

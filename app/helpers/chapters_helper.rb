module ChaptersHelper

  private

  # Returns the chapters for which we can see/solve the exercises
  def accessible_chapters(columns)
    return Chapter.select(get_chapter_columns_string(columns)) if (@signed_in and current_user.sk.admin?)
    
    return Chapter.find_by_sql("SELECT #{get_chapter_columns_string(columns)}
                                FROM chapters
                                WHERE chapters.online = #{true_value_sql}
                                AND (chapters.section_id IN #{fondations_sections_request}
                                     OR #{num_chapter_unsolved_prerequisites_request} = 0
                                    )")
  end
  
  # Returns the chapters of one section for which we can solve the exercises
  def accessible_chapters_from_section(section, columns)
    return section.chapters.select(get_chapter_columns_string(columns)) if (@signed_in and current_user.sk.admin?)
    
    if section.fondation?
      return section.chapters.select(get_chapter_columns_string(columns)).where(:online => true)
    else
      return Chapter.find_by_sql("SELECT #{get_chapter_columns_string(columns)}
                                  FROM chapters
                                  WHERE chapters.section_id = #{section.id}
                                  AND chapters.online = #{true_value_sql}
                                  AND #{num_chapter_unsolved_prerequisites_request} = 0")
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
  
  def num_chapter_unsolved_prerequisites_request
    return "(SELECT COUNT(prerequisites.prerequisite_id)
             FROM prerequisites
             WHERE prerequisites.chapter_id = chapters.id
             AND prerequisites.prerequisite_id NOT IN #{chapters_completed_request})"
  end
  
  def fondations_sections_request
    return "(" + Section.where(:fondation => true).select(:id).to_sql + ")"
  end
  
  def chapters_completed_request
    if !@signed_in
      return "()"
    else
      return "(" + current_user.sk.chapters.select(:id).to_sql + ")"
    end
  end
end
